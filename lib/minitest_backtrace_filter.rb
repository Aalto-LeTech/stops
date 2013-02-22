# Include Backtrace filtering for Test::Unit tests (Test::Unit uses MiniTest.filter_backtrace
# which the following  will override so that rails BacktraceCleaner will be used).
module MiniTest
  def self.filter_backtrace_with_cleaning(bt)
    filter_backtrace_without_cleaning(Rails.backtrace_cleaner.clean(bt))
  end

  class << self
    alias :filter_backtrace_without_cleaning :filter_backtrace
    alias :filter_backtrace :filter_backtrace_with_cleaning
  end
end
