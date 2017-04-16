require 'test_helper'

class DetectRealCallsTest < Test::Unit::TestCase
	PATTERN = /(?:^|\s+)Real(?:File|FileTest|FileUtils|Dir|Pathname)\.\w+/
	

	def test_no_real_calls_are_ever_made
		matches = []
		Dir['lib/**/*.rb'].each do |file|
			File.readlines(file).each_with_index do |line, i|
				matches << [file, i, line.strip] if PATTERN.match line
			end
		end

 		assert_equal 0, matches.length, format_failures(matches)
	end


	# Hackish formatter method to display 'file:lineno____offending line content' from the failures array of arrays
	def format_failures(failures)
		result = "\nThe following line(s) appear to make direct calls to real filesystem classes:\n\n"

		width = failures.max_by{|x| x[0].length}[0].length + 4
		failures.each do |failure|
			result << "#{failure[0]}:#{'%03i' % failure[1]}:#{' ' * (width - failure[0].length)}#{failure[2]}\n"
		end

		result
	end
end

