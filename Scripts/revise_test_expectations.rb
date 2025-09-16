#!/usr/bin/env ruby

# Minimal updater: parses Swift Testing heredoc diffs from `swift test` output
# and writes new heredoc content into the corresponding test files under ./Tests.
#
# Use this script when source code changes make test expectations obsolete. It finds
# heredocs with test errors, and updates the expected text to match the actual output.

def run_swift_tests
    output = +""
    begin
        IO.popen(%w[swift test], err: [:child, :out]) do |io|
            io.each_line do |line|
                sanitized_line = line.gsub("\u2007", " ")
                print sanitized_line
                output << sanitized_line
            end
        end
    rescue Errno::ENOENT
        warn "Error: 'swift' command not found."
        exit 1
    end
    output
end

def parse_new_heredoc_content(diff)
    puts "parse_new_heredoc_content"
    puts diff
    lines = diff.strip.lines
    inner = lines[1..-2] || []
    inner.map do |l|
        # Check original line with indentation to distinguish diff markers from markdown
        if l =~ /^\s{5}\+/
            nil
        elsif l =~ /^\s{5}\u2212/
            # Remove the diff marker and indentation, keep the content
            l[7..-1].to_s.chomp
        else
            # Not a diff marker, just trim and keep the line
            l.lstrip.chomp
        end
    end.compact
end

def find_in_tests(basename)
    Dir.glob('Tests/**/*').find { |p| File.file?(p) && File.basename(p) == basename }
end

def apply_changes(file_path, changes)
    lines = File.readlines(file_path, chomp: false)

    # Sort changes by line number in descending order (bottom to top)
    # so that line number shifts don't affect subsequent changes
    changes.sort_by! { |c| -c[:line] }
    applied = 0

    changes.each_with_index do |ch, idx|
        puts "  Processing change #{idx + 1}/#{changes.length} at line #{ch[:line]}"

        # Track cumulative line shifts from previous changes
        error_idx = [ch[:line] - 1, 0].max
        puts "    Error index: #{error_idx}"

        # Find enclosing @Test block (nearest above the error line)
        func_decl = nil
        i = [error_idx, lines.length - 1].min
        while i >= 0
            if lines[i].include?('@Test("')
                func_decl = i
                break
            end
            i -= 1
        end

        unless func_decl
            puts "    ❌ No @Test block found above line #{ch[:line]}"
            next
        end
        puts "    Found @Test at line #{func_decl + 1}"

        # Test block end: next @Test or EOF
        test_end = lines.length
        j = func_decl + 1
        while j < lines.length
            if lines[j].strip.start_with?('@Test("')
                test_end = j
                break
            end
            j += 1
        end
        puts "    Test block spans lines #{func_decl + 1} to #{test_end}"

        # Find heredoc ranges within the block
        heredocs = []
        k = func_decl + 1
        while k < test_end
            if lines[k].include?('"""')
                s = k
                e = k + 1
                e += 1 while e < test_end && !lines[e].include?('"""')
                break if e >= test_end
                heredocs << [s, e]
                k = e + 1
            else
                k += 1
            end
        end

        if heredocs.empty?
            puts "    ❌ No heredocs found in test block"
            next
        end
        puts "    Found #{heredocs.length} heredoc(s): #{heredocs.map { |s, e| "#{s + 1}-#{e + 1}" }.join(', ')}"

        # Find expectNoDifference calls and match to error line
        expect_calls = []
        k = func_decl + 1
        while k < test_end
            if lines[k].include?('expectNoDifference')
                puts "    DEBUG: Found expectNoDifference at line #{k + 1}: #{lines[k].strip}"
                # Find the heredoc associated with this expectNoDifference call
                heredoc_start = nil
                heredoc_end = nil

                # Look for heredoc after this expectNoDifference line (within next 10 lines)
                j = k + 1
                search_limit = [k + 10, test_end].min
                while j < search_limit
                    if lines[j].include?('"""')
                        heredoc_start = j
                        # Find heredoc end
                        m = j + 1
                        m += 1 while m < test_end && !lines[m].include?('"""')
                        if m < test_end
                            heredoc_end = m
                            expect_calls << {
                                expect_line: k,
                                heredoc_start: heredoc_start,
                                heredoc_end: heredoc_end
                            }
                            puts "    DEBUG: Associated heredoc found at lines #{heredoc_start + 1}-#{heredoc_end + 1}"
                        end
                        break
                    end
                    j += 1
                end
                k = heredoc_end ? heredoc_end + 1 : k + 1
            else
                k += 1
            end
        end

        if expect_calls.empty?
            puts "    ❌ No expectNoDifference calls with heredocs found in test block"
            puts "    DEBUG: Lines #{func_decl + 1} to #{test_end}:"
            (func_decl + 1...test_end).each do |i|
                puts "    #{i + 1}: #{lines[i].strip}" if lines[i].include?('expect') || lines[i].include?('"""')
            end
            next
        end

        puts "    Found #{expect_calls.length} expectNoDifference call(s) with heredocs: #{expect_calls.map { |c| "line #{c[:expect_line] + 1}" }.join(', ')}"

        # Find the expectNoDifference call that contains or is closest to the error line
        target_heredoc = nil
        best_expect_call = nil
        min_distance = Float::INFINITY

        expect_calls.each do |call|
            # Calculate distance from error line to this expectNoDifference call
            distance = if error_idx >= call[:expect_line] && error_idx <= call[:heredoc_end]
                0  # Error line is within this expectNoDifference block
            elsif error_idx < call[:expect_line]
                call[:expect_line] - error_idx  # Error line is before this call
            else
                error_idx - call[:heredoc_end]  # Error line is after this call
            end

            if distance < min_distance
                min_distance = distance
                best_expect_call = call
                target_heredoc = [call[:heredoc_start], call[:heredoc_end]]
            end
        end

        unless target_heredoc
            puts "    ❌ No matching expectNoDifference call found for error line"
            next
        end

        puts "    ✓ Selected expectNoDifference call at line #{best_expect_call[:expect_line] + 1} (distance: #{min_distance})"

        hs, he = target_heredoc
        puts "    ✓ Found target heredoc at lines #{hs + 1}-#{he + 1}"

        # Get base indentation from closing heredoc line
        base_indent = (lines[he][/^\s*/] || "")

        # Process new content
        new_body = ch[:new].map { |ln|
            if ln.start_with?('− ')
                ln[2..-1] || ""
            else
                ln
            end
        }

        # Format with proper indentation
        replaced = new_body.map { |ln|
            ln.strip.empty? ? "\n" : "#{base_indent}#{ln}\n"
        }

        # Replace the content between heredoc markers
        old_line_count = he - hs - 1
        new_line_count = replaced.length

        lines[(hs + 1)...he] = replaced
        applied += 1

        puts "  - Updated heredoc at line #{hs + 1} (#{old_line_count} → #{new_line_count} lines)"
    end

    if applied > 0
        File.write(file_path, lines.join)
        puts "✓ Updated #{file_path} (#{applied} change#{applied == 1 ? '' : 's'})."
    end
end

def find_test_failures(output)
    failures = []

    # Step 1: Find all test failure lines
    test_failure_lines = []
    output.lines.each_with_index do |line, idx|
        if line.include?('recorded an issue at') && line.include?('.swift:')
            # Extract test name, file, and line number
            if line =~ /Test\s+"([^"]+)".*?at\s+([^:]+\.swift):(\d+):/
                test_failure_lines << {
                    test_name: $1,
                    file: $2,
                    line: $3.to_i,
                    line_index: idx
                }
            end
        end
    end

    # Step 2: For each test failure, find the corresponding heredoc
    output_lines = output.lines
    test_failure_lines.each do |failure|

        # Look for "Difference:" followed by heredoc starting from the failure line
        start_search = failure[:line_index]
        diff_line_idx = nil

        (start_search...[output_lines.length, start_search + 20].min).each do |i|
            if output_lines[i].include?('Difference:')
                diff_line_idx = i
                break
            end
        end

        next unless diff_line_idx

        # Look for heredoc starting after the Difference line
        heredoc_start = nil
        heredoc_end = nil

        (diff_line_idx + 1...output_lines.length).each do |i|
            if output_lines[i].strip == '"""'
                heredoc_start = i
                break
            end
        end

        next unless heredoc_start

        # Find heredoc end
        (heredoc_start + 1...output_lines.length).each do |i|
            if output_lines[i].strip == '"""'
                heredoc_end = i
                break
            end
        end

        next unless heredoc_end

        # Extract heredoc content
        heredoc_lines = output_lines[(heredoc_start)..(heredoc_end)]
        heredoc_content = heredoc_lines.join

        failures << {
            test: failure[:test_name],
            file: failure[:file],
            line: failure[:line],
            diff: heredoc_content
        }
    end

    failures
end

def main
    puts "Running Swift tests..."
    out = run_swift_tests

    puts "\nDEBUG: Scanning output for test failures..."
    failures = find_test_failures(out)

    if failures.empty?
        puts "No failing tests with heredoc diffs found."
        return
    end

    puts "\nFound #{failures.length} failing test#{failures.length == 1 ? '' : 's'} with heredoc diffs."

    grouped = failures.group_by { |f| File.basename(f[:file]) }
    grouped.each do |basename, group|
        path = find_in_tests(basename)
        unless path
            puts "⚠️  Could not find #{basename} in Tests directory"
            next
        end

        puts "\nProcessing #{basename} (#{group.length} change#{group.length == 1 ? '' : 's'}):"
        changes = group.map { |f|
            { line: f[:line], new: parse_new_heredoc_content(f[:diff]) }
        }

        apply_changes(path, changes)
    end

    puts "\nDone!"
end

main
