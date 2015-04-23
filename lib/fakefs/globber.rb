module FakeFS
  # Handles globbing for FakeFS.
  module Globber
    extend self

    def expand(pattern)
      return [pattern] if pattern[0] != '{' || pattern[-1] != '}'

      part = ''
      result = []

      each_char_with_levels pattern, '{', '}' do |chr, level|
        case level
        when 0
          case chr
          when '{'
            # noop
          else
            part << chr
          end
        when 1
          case chr
          when ','
            result << part
            part = ''
          when '}'
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

    def regexp(pattern)
      regex_body = pattern.gsub('.', '\.')
                          .gsub('?', '.')
                          .gsub('*', '.*')
                          .gsub('(', '\(')
                          .gsub(')', '\)')
                          .gsub(/\{(.*?)\}/) do
                            "(#{Regexp.last_match[1].gsub(',', '|')})"
                          end
                          .gsub(/\A\./, '(?!\.).')
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
