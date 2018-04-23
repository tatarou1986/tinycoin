module Tinycoin
  module Logger
    LEVELS = {:debug => 0, :info => 1, :warn => 2, :error => 3, :fatal => 4}

    def self.level_to_num level
      LEVELS[level]
    end

    def self.create name, level = :info
      dir = "log"
      FileUtils.mkdir_p(dir) rescue dir = nil
      @log = Log4r::Logger.new(name.to_s)
      @log.level = level_to_num(level)
      formatter = Log4r::PatternFormatter.new(:pattern => "%d %C[%l]: %M",
                                              :date_format => "%Y/%m/%d %H:%M:%S,%L")
      @log.outputters << Log4r::StdoutOutputter.new(STDOUT, :formatter => formatter)
      @log.outputters << Log4r::FileOutputter.new("fout", :filename => "#{dir}/all.log", :formatter => formatter)  if dir
      @log
    end
  end
end
