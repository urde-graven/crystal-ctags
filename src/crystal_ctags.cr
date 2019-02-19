require "compiler/crystal/syntax"

require "./crystal_ctags/version"

module CrystalCtags
  TAGS = {
    :class  => "c",
    :module => "m",
    :def    => "d",
    :macros => "x",
    :lib    => "l",
    :struct => "s",
    :fun    => "f",
  }

  enum ExCmd
    NUMBER
    PATTERN
    MIX
  end

  class Tag
    @name : String
    @filename : String
    @excmd : String
    @kind : Symbol
    @line : Int32?
    @scope : Array(String)?
    @signature : String?
    @type : String?

    def initialize(@name, @filename, @excmd, @kind, @line = nil, @scope = nil, @signature = nil, @type = nil)
    end

    def to_s(io)
      io << @name << "\t" << @filename << "\t" << @excmd << ";\"\t" << TAGS[@kind]
      io << "\tline:" << @line unless @line.nil?
      io << "\tnamespace:" << @scope.not_nil!.join(".") unless @scope.not_nil!.empty?
      io << "\tsignature:" << @signature unless @signature.nil?
      io << "\ttype:" << @type unless @type.nil?
    end
  end

  class CtagsVisitor < Crystal::Visitor
    getter tags

    @filename : String
    @content : String
    @relative : Bool
    @excmd : ExCmd

    def initialize(@filename, @content, @relative, @excmd)
      @tags = [] of CrystalCtags::Tag
      @scope = [] of String
    end

    def visit(node : Crystal::ClassDef)
      process_node node, node.name.names.last, :class
      @scope << node.name.names.last
      true
    end

    def visit(node : Crystal::ModuleDef)
      process_node node, node.name.names.last, :module
      @scope << node.name.names.last
      true
    end

    def visit(node : Crystal::Def)
      first_line = node.to_s.lines.first
      start_args = first_line.index(node.name).not_nil! + node.name.size
      signature = first_line[start_args..-1].rstrip
      signature = nil if signature.size == 0

      process_node node, node.name, :def, signature
      false
    end

    def visit(node : Crystal::Macro)
      process_node node, node.name, :macros
      true
    end

    def visit(node : Crystal::LibDef)
      process_node node, node.name, :lib
      @scope << node.name
      true
    end

    def visit(node : Crystal::StructOrUnionDef)
      process_node node, node.name, :struct
      @scope << node.name
      true
    end

    def visit(node : Crystal::FunDef)
      process_node node, node.name, :fun
      true
    end

    def visit(node : Crystal::Expressions)
      true
    end

    def visit(node : Crystal::ASTNode)
      true
    end

    def end_visit(node : Crystal::ClassDef | Crystal::ModuleDef | Crystal::CStructOrUnionDef | Crystal::LibDef)
      return unless node.location
      @scope.pop?
    end

    def process_node(node, name : String, kind : Symbol, signature : String | Nil = nil)
      location = node.location
      return true unless location

      filename = location.filename
      return true unless filename.is_a?(String)

      line_number = location.line_number
      line = @content.lines[line_number - 1]
      excmd = extcmdize(line, location)

      tag = CrystalCtags::Tag.new(name, relativize(@filename), excmd, kind, line_number, @scope.dup, signature)
      @tags << tag

      true
    end

    def relativize(filename)
      if @relative && filename.starts_with?(Dir.current)
        filename = filename[Dir.current.size..-1]
        filename = filename[1..-1] if filename.starts_with?("/")
      end

      filename
    end

    def extcmdize(str : String, location)
      case @excmd
      when ExCmd::MIX
        "#{location.line_number};/^#{regexpize(str)}$/"
      when ExCmd::NUMBER
        location.line_number.to_s
      when ExCmd::PATTERN
        "/^#{regexpize(str)}$/"
      else
        raise KeyError.new
      end
    end

    def regexpize(str : String)
      str.gsub(/\r\n|\r|\n/, "").gsub(/[\\\/$^]/, "\\\\\\0")
    end
  end

  class Ctags

    def initialize(filenames, @append = false, @relative = false, @excmd = ExCmd::NUMBER)
      @files = {} of String => String

      filenames.map! do |filename|
        File.expand_path(filename)
      end
      filenames.each do |filename|
        content = File.read(filename)
        @files[filename] = content
      end
    end

    def parse
      @files.each do |filename, content|
        begin
          parser = Crystal::Parser.new(content)
          parser.filename = filename
          node = parser.parse
          visitor = CrystalCtags::CtagsVisitor.new(filename, content, @relative, @excmd)
          node.accept(visitor)
          yield visitor.tags
        rescue e : Crystal::SyntaxException
          STDERR.puts "WARN: #{filename}:#{e.line_number}: #{e.message}"
        end
      end
    end

    def to_s(io)
      unless @append
        # Headers
        io << "!_TAG_FILE_FORMAT 2 /extended format; --format=1 will not append ;\" to lines/\n"
        io << "!_TAG_FILE_SORTED 0 /0=unsorted, 1=sorted, 2=foldcase/\n"
        io << "!_TAG_PROGRAM_VERSION #{CrystalCtags::VERSION} //\n"
      end

      # Tags
      parse do |tags|
        tags.each do |tag|
          io << tag << "\n"
        end
      end
    end
  end
end
