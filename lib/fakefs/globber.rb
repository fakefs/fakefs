module FakeFS
  # Handles globbing for FakeFS.
  module Globber
    extend self

    def expand(pattern)
      pattern = pattern.to_s

      return [pattern] if pattern[0] != '{' || pattern[-1] != '}'

      part = ''
      result = []

      each_char_with_levels pattern, '{', '}' do |chr, level|
        case level
        when 0
          case chr
          when '{' # rubocop:disable Lint/EmptyWhen
            # noop
          else
            part << chr
          end
        when 1
          case chr
          when ','
            result << part
            part = ''
          when '}' # rubocop:disable Lint/EmptyWhen
            # noop
          else
            part << chr
          end
        else
          part << chr
        end
      end

      result << part

      result
    end

    def path_components(pattern)
      pattern = pattern.to_s

      part = ''
      result = []

      each_char_with_levels pattern, '{', '}' do |chr, level|
        if level == 0 && chr == File::SEPARATOR
          result << part
          part = ''
        else
          part << chr
        end
      end

      result << part

      drop_root(result).reject(&:empty?)
    end

    def regexp(pattern, find_flags = 0, gave_char_class = false)
      pattern = pattern.to_s

      regex_body =
        pattern
        .gsub('.', '\.')
        .gsub('+') { '\+' }
        .gsub('?', '.')
        .gsub('*', '.*')
        .gsub('(', '\(')
        .gsub(')', '\)')
        .gsub('$', '\$')

      # unless we're expecting character class contructs in regexes, escape all brackets
      # since if we're expecting them, the string should already be properly escaped
      unless gave_char_class
        regex_body = regex_body.gsub('[', '\[').gsub(']', '\]')
      end

      # This matches nested braces and attempts to do something correct most of the time
      # There are known issues (i.e. {,*,*/*}) that cannot be resolved with out a total
      # refactoring
      loop do
        break unless regex_body.gsub!(/(?<re>\{(?:(?>[^{}]+)|\g<re>)*\})/) do
          "(#{Regexp.last_match[1][1..-2].gsub(',', '|')})"
        end
      end

      # if we are matching dot files/directories, add that to the regex
      if find_flags == File::FNM_DOTMATCH
        regex_body = "(\.)?" + regex_body
      end

      regex_body = regex_body.gsub(/\A\./, '(?!\.).')
      /\A#{regex_body}\Z/
    end

    private

    def each_char_with_levels(string, level_start, level_end)
      level = 0

      string.each_char do |chr|
        yield chr, level

        case chr
        when level_start
          level += 1
        when level_end
          level -= 1
        end
      end
    end

    def drop_root(path_parts)
      # we need to remove parts from root dir at least for windows and jruby
      return path_parts if path_parts.nil? || path_parts.empty?
      root = RealFile.expand_path('/').split(File::SEPARATOR).first
      path_parts.shift if path_parts.first == root
      path_parts
    end
  end
end
