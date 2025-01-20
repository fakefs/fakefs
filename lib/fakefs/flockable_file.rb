# frozen_string_literal: true

require_relative 'file'

module FakeFS
  # Be careful using this, as it may break things if
  # you obtain more that one flock per file using
  # different descriptors.
  # Real flock call blocks/returns false in that case -
  # see https://man7.org/linux/man-pages/man2/flock.2.html,
  # it says it "may be denied", but it does, it fact, deny.
  # This implementation simply returns 0.
  # This may also be a problem if you, it fact, are accessing a
  # real file, which is locked by another process.
  class File < StringIO
    # yep, File::LOCK_UN | File::LOCK_NB is allowed
    FAKE_FS_ALLOWED_FLOCK_MODES = [RealFile::LOCK_EX, RealFile::LOCK_SH, RealFile::LOCK_UN].flat_map do |mode|
      [mode, mode | RealFile::LOCK_NB]
    end.freeze

    remove_method :flock

    def flock(mode)
      # all successful calls - even UN - seem to return 0
      unless mode.is_a?(Integer)
        unless mode.respond_to?(:to_int)
          raise TypeError, "no implicit conversion of #{mode.class} into Integer"
        end
        int_mode = mode.to_int

        unless int_mode.is_a?(Integer)
          raise TypeError, "can't convert #{mode.class} to Integer (#{mode.class}#to_int gives #{int_mode.class})"
        end
        mode = int_mode
      end

      # In fact, real implementation may not fail on `flock 11111` -
      # - but fails with `f1.flock 11111111` - or may fail
      # with another error - `f1.flock 1111111111111` gives
      # `integer 1111111111111 too big to convert to `int' (RangeError)`
      # - but I think it's safer to allow only documented modes.
      unless FAKE_FS_ALLOWED_FLOCK_MODES.include?(mode)
        # real exception
        # Invalid argument @ rb_file_flock - filepath (Errno::EINVAL)
        # raise Errno::EINVAL.new(@path, 'rb_file_flock')
        # represents it better, but fails on JRuby
        raise Errno::EINVAL, @path
      end
      0
    end
  end
end
