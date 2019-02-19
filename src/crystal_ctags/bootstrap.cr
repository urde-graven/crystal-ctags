require "../crystal_ctags"
require "option_parser"

class Config
  property filenames = [] of String
  property tagfile   = "tags"
  property append    = false
  property recurse   = false
  property excmd     = CrystalCtags::ExCmd::MIX
end

def invalid_options(flag, opts)
  STDERR.puts "ERROR: #{flag} is not a valid option."
  STDERR.puts opts
  exit 1
end

def parse_options(args, config)
  OptionParser.parse(args, consume_args: false) do |opts|
    opts.banner = "Usage: #{PROGRAM_NAME} [options] [--] [files]\n\nOptions:"
    opts.on("-h", "--help", "Show this help") { puts opts }
    opts.on("-f tagfile", "Use the name specified by tagfile for the tag file (default is `tags')") do |file|
      config.tagfile = file
    end
    opts.on("-L file", "A list of input file names is read from the specified file. \
              If specified as \"-\", then standard input is read.") do |file|
      if file == "-"
        STDIN.each_line { |line| config.filenames << line }
      else
        File.each_line(file) { |line| config.filenames << line }
      end
    end
    opts.on("-R", "--recurse=[yes|no]", "Recurse into directories encountered in the list of supplied files.") do |v|
      config.recurse = v != "no"
    end
    opts.on("--options=pathname", "Read additional options from file or directory.") do |file|
      parse_options(File.read_lines(file).reject(&.blank?), config)
      # TODO error for files
    end
    opts.on("-a", "--append=[yes|no]", "Append the tags to an existing tag file.") do |v|
      config.append = v != "no"
    end
    opts.on("--exclude=[pattern]", "TODO") { }
    opts.on("--excmd=number|pattern|mix", "Uses the specified type of EX command to locate tags [mix]") do |v|
      config.excmd = case v
      when "n", "number"  then CrystalCtags::ExCmd::NUMBER
      when "p", "pattern" then CrystalCtags::ExCmd::PATTERN
      when "m", "mix"     then CrystalCtags::ExCmd::MIX
      else invalid_options("--excmd=#{v}", opts)
      end
    end
    opts.invalid_option { |flag| invalid_options(flag, opts) }
    opts.missing_option { |flag| invalid_options("#{flag} without value", opts) }
    opts.unknown_args do |before, after|
      config.filenames.concat(before)
      config.filenames.concat(after)
    end
  end
end

config = Config.new
parse_options(ARGV, config)

if config.filenames.empty? 
  STDERR.puts "ERROR: No files specified."
  exit 1
end

filenames = Set(String).new
config.filenames.each do |name|
  if File.directory?(name)
    if config.recurse
      escaped = name.gsub(/[*{\\\[?]/) { |ch| "\\#{ch}" }
      Dir.glob("#{escaped}/**/*.cr", match_hidden: true) { |file| filenames << file if File.file?(file) }
    end
  else
    filenames << name if name.ends_with?(".cr") && File.file?(name)
  end
end

ctags = CrystalCtags::Ctags.new(filenames.to_a, append: config.append, relative: false, excmd: config.excmd)

if config.tagfile == "-"
  print ctags
else
  File.write(config.tagfile, ctags, mode: config.append ? "a" : "w")
end

