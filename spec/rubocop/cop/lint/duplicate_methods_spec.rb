# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Lint::DuplicateMethods do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  shared_examples 'in scope' do |type, opening_line|
    it "registers an offense for duplicate method in #{type}" do
      expect_offense(<<-RUBY.strip_indent)
        #{opening_line}
          def some_method
            implement 1
          end
          def some_method
          ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both (string):2 and (string):5.
            implement 2
          end
        end
      RUBY
    end

    it "doesn't register an offense for non-duplicate method in #{type}" do
      expect_no_offenses(<<-RUBY.strip_indent)
        #{opening_line}
          def some_method
            implement 1
          end
          def any_method
            implement 2
          end
        end
      RUBY
    end

    it "registers an offense for duplicate class methods in #{type}" do
      expect_offense(<<-RUBY.strip_indent, 'dups.rb')
        #{opening_line}
          def self.some_method
            implement 1
          end
          def self.some_method
          ^^^^^^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both dups.rb:2 and dups.rb:5.
            implement 2
          end
        end
      RUBY
    end

    it "doesn't register offense for non-duplicate class methods in #{type}" do
      expect_no_offenses(<<-RUBY.strip_indent)
        #{opening_line}
          def self.some_method
            implement 1
          end
          def self.any_method
            implement 2
          end
        end
      RUBY
    end

    it "recognizes difference between instance and class methods in #{type}" do
      expect_no_offenses(<<-RUBY.strip_indent)
        #{opening_line}
          def some_method
            implement 1
          end
          def self.some_method
            implement 2
          end
        end
      RUBY
    end

    it "registers an offense for duplicate private methods in #{type}" do
      expect_offense(<<-RUBY.strip_indent)
        #{opening_line}
          private def some_method
            implement 1
          end
          private def some_method
                  ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both (string):2 and (string):5.
            implement 2
          end
        end
      RUBY
    end

    it "registers an offense for duplicate private self methods in #{type}" do
      expect_offense(<<-RUBY.strip_indent)
        #{opening_line}
          private def self.some_method
            implement 1
          end
          private def self.some_method
                  ^^^^^^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both (string):2 and (string):5.
            implement 2
          end
        end
      RUBY
    end

    it "doesn't register an offense for different private methods in #{type}" do
      expect_no_offenses(<<-RUBY.strip_indent)
        #{opening_line}
          private def some_method
            implement 1
          end
          private def any_method
            implement 2
          end
        end
      RUBY
    end

    it "registers an offense for duplicate protected methods in #{type}" do
      expect_offense(<<-RUBY.strip_indent)
        #{opening_line}
          protected def some_method
            implement 1
          end
          protected def some_method
                    ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both (string):2 and (string):5.
            implement 2
          end
        end
      RUBY
    end

    it "registers 2 offenses for pair of duplicate methods in #{type}" do
      expect_offense(<<-RUBY.strip_indent, 'dups.rb')
        #{opening_line}
          def some_method
            implement 1
          end
          def some_method
          ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both dups.rb:2 and dups.rb:5.
            implement 2
          end
          def any_method
            implement 1
          end
          def any_method
          ^^^^^^^^^^^^^^ Method `A#any_method` is defined at both dups.rb:8 and dups.rb:11.
            implement 2
          end
        end
      RUBY
    end

    it 'registers an offense for a duplicate instance method in separate ' \
       "#{type} blocks" do
      expect_offense(<<-RUBY.strip_indent, 'dups.rb')
        #{opening_line}
          def some_method
            implement 1
          end
        end
        #{opening_line}
          def some_method
          ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both dups.rb:2 and dups.rb:7.
            implement 2
          end
        end
      RUBY
    end

    it 'registers an offense for a duplicate class method in separate ' \
       "#{type} blocks" do
      inspect_source(<<-RUBY.strip_indent)
        #{opening_line}
          def self.some_method
            implement 1
          end
        end
        #{opening_line}
          def self.some_method
            implement 2
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(1)
    end

    it 'registers offense for a duplicate instance method in separate files' do
      inspect_source(<<-RUBY.strip_indent, 'first.rb')
        #{opening_line}
          def some_method
            implement 1
          end
        end
      RUBY
      expect_offense(<<-RUBY.strip_indent, 'second.rb')
        #{opening_line}
          def some_method
          ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both first.rb:2 and second.rb:2.
            implement 2
          end
        end
      RUBY
    end

    it 'understands class << self' do
      expect_offense(<<-RUBY.strip_indent, 'test.rb')
        #{opening_line}
          class << self
            def some_method
              implement 1
            end
            def some_method
            ^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both test.rb:3 and test.rb:6.
              implement 2
            end
          end
        end
      RUBY
    end

    it 'understands nested modules' do
      expect_offense(<<-RUBY.strip_indent, 'test.rb')
        module B
          #{opening_line}
            def some_method
              implement 1
            end
            def some_method
            ^^^^^^^^^^^^^^^ Method `B::A#some_method` is defined at both test.rb:3 and test.rb:6.
              implement 2
            end
            def self.another
            end
            def self.another
            ^^^^^^^^^^^^^^^^ Method `B::A.another` is defined at both test.rb:9 and test.rb:11.
            end
          end
        end
      RUBY
    end

    it 'registers an offense when class << exp is used' do
      pending
      inspect_source(<<-RUBY.strip_indent, 'test.rb')
        #{opening_line}
          class << blah
            def some_method
              implement 1
            end
            def some_method
              implement 2
            end
          end
        end
      RUBY
      expect(cop.offenses.empty?).to be(false)
    end

    it "registers an offense for duplicate alias in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          def some_method
            implement 1
          end
          alias some_method any_method
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both example.rb:2 and example.rb:5.
        end
      RUBY
    end

    it "doesn't register an offense for non-duplicate alias in #{type}" do
      expect_no_offenses(<<-RUBY)
        #{opening_line}
          def some_method
            implement 1
          end
          alias any_method some_method
        end
      RUBY
    end

    it "registers an offense for duplicate alias_method in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          def some_method
            implement 1
          end
          alias_method :some_method, :any_method
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both example.rb:2 and example.rb:5.
        end
      RUBY
    end

    it "accepts for non-duplicate alias_method in #{type}" do
      expect_no_offenses(<<-RUBY)
        #{opening_line}
          def some_method
            implement 1
          end
          alias_method :any_method, :some_method
        end
      RUBY
    end

    it "doesn't register an offense for alias for gvar in #{type}" do
      expect_no_offenses(<<-RUBY)
        #{opening_line}
          alias $foo $bar
        end
      RUBY
    end

    it "registers an offense for duplicate attr_reader in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          def something
          end
          attr_reader :something
          ^^^^^^^^^^^^^^^^^^^^^^ Method `A#something` is defined at both example.rb:2 and example.rb:4.
        end
      RUBY
    end

    it "registers an offense for duplicate attr_writer in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          def something=(right)
          end
          attr_writer :something
          ^^^^^^^^^^^^^^^^^^^^^^ Method `A#something=` is defined at both example.rb:2 and example.rb:4.
        end
      RUBY
    end

    it "registers offenses for duplicate attr_accessor in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          attr_accessor :something

          def something
          ^^^^^^^^^^^^^ Method `A#something` is defined at both example.rb:2 and example.rb:4.
          end
          def something=(right)
          ^^^^^^^^^^^^^^ Method `A#something=` is defined at both example.rb:2 and example.rb:6.
          end
        end
      RUBY
    end

    it "registers an offense for duplicate attr in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          def something
          end
          attr :something
          ^^^^^^^^^^^^^^^ Method `A#something` is defined at both example.rb:2 and example.rb:4.
        end
      RUBY
    end

    it "registers offenses for duplicate assignable attr in #{type}" do
      expect_offense(<<-RUBY, 'example.rb')
        #{opening_line}
          attr :something, true

          def something
          ^^^^^^^^^^^^^ Method `A#something` is defined at both example.rb:2 and example.rb:4.
          end
          def something=(right)
          ^^^^^^^^^^^^^^ Method `A#something=` is defined at both example.rb:2 and example.rb:6.
          end
        end
      RUBY
    end

    it "accepts for attr_reader and setter in #{type}" do
      expect_no_offenses(<<-RUBY)
        #{opening_line}
          def something=(right)
          end
          attr_reader :something
        end
      RUBY
    end

    it "accepts for attr_writer and getter in #{type}" do
      expect_no_offenses(<<-RUBY)
        #{opening_line}
          def something
          end
          attr_writer :something
        end
      RUBY
    end
  end

  include_examples('in scope', 'class', 'class A')
  include_examples('in scope', 'module', 'module A')
  include_examples('in scope', 'dynamic class', 'A = Class.new do')
  include_examples('in scope', 'dynamic module', 'A = Module.new do')
  include_examples('in scope', 'class_eval block', 'A.class_eval do')

  %w[class module].each do |type|
    it 'registers an offense for duplicate class methods with named receiver ' \
       "in #{type}" do
      expect_offense(<<-RUBY.strip_indent, 'src.rb')
        #{type} A
          def A.some_method
            implement 1
          end
          def A.some_method
          ^^^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both src.rb:2 and src.rb:5.
            implement 2
          end
        end
      RUBY
    end

    it 'registers an offense for duplicate class methods with `self` and ' \
       "named receiver in #{type}" do
      expect_offense(<<-RUBY.strip_indent, 'src.rb')
        #{type} A
          def self.some_method
            implement 1
          end
          def A.some_method
          ^^^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both src.rb:2 and src.rb:5.
            implement 2
          end
        end
      RUBY
    end

    it 'registers an offense for duplicate class methods with `<<` and named ' \
       "receiver in #{type}" do
      expect_offense(<<-RUBY.strip_indent, 'test.rb')
        #{type} A
          class << self
            def some_method
              implement 1
            end
          end
          def A.some_method
          ^^^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both test.rb:3 and test.rb:7.
            implement 2
          end
        end
      RUBY
    end
  end

  it 'registers an offense for duplicate methods at top level' do
    expect_offense(<<-RUBY.strip_indent, 'toplevel.rb')
      def some_method
        implement 1
      end
      def some_method
      ^^^^^^^^^^^^^^^ Method `Object#some_method` is defined at both toplevel.rb:1 and toplevel.rb:4.
        implement 2
      end
    RUBY
  end

  it 'understands class << A' do
    expect_offense(<<-RUBY.strip_indent, 'test.rb')
      class << A
        def some_method
          implement 1
        end
        def some_method
        ^^^^^^^^^^^^^^^ Method `A.some_method` is defined at both test.rb:2 and test.rb:5.
          implement 2
        end
      end
    RUBY
  end

  it 'handles class_eval with implicit receiver' do
    expect_offense(<<-RUBY.strip_indent, 'test.rb')
      module A
        class_eval do
          def some_method
            implement 1
          end
          def some_method
          ^^^^^^^^^^^^^^^ Method `A#some_method` is defined at both test.rb:3 and test.rb:6.
            implement 2
          end
        end
      end
    RUBY
  end

  it 'ignores method definitions in RSpec `describe` blocks' do
    expect_no_offenses(<<-RUBY.strip_indent)
      describe "something" do
        def some_method
          implement 1
        end
        def some_method
          implement 2
        end
      end
    RUBY
  end

  it 'ignores Class.new blocks which are assigned to local variables' do
    expect_no_offenses(<<-RUBY.strip_indent)
      a = Class.new do
        def foo
        end
      end
      b = Class.new do
        def foo
        end
      end
    RUBY
  end

  context 'when path is in the project root' do
    before do
      allow(Dir).to receive(:pwd).and_return('/path/to/project/root')
      allow_any_instance_of(Parser::Source::Buffer).to receive(:name)
        .and_return('/path/to/project/root/lib/foo.rb')
    end

    it 'adds a message with relative path' do
      expect_offense(<<-RUBY.strip_indent)
        def something
        end
        def something
        ^^^^^^^^^^^^^ Method `Object#something` is defined at both lib/foo.rb:1 and lib/foo.rb:3.
        end
      RUBY
    end
  end

  context 'when path is not in the project root' do
    before do
      allow(Dir).to receive(:pwd).and_return('/path/to/project/root')
      allow_any_instance_of(Parser::Source::Buffer).to receive(:name)
        .and_return('/no/project/root/foo.rb')
    end

    it 'adds a message with absolute path' do
      expect_offense(<<-RUBY.strip_indent)
        def something
        end
        def something
        ^^^^^^^^^^^^^ Method `Object#something` is defined at both /no/project/root/foo.rb:1 and /no/project/root/foo.rb:3.
        end
      RUBY
    end
  end
end
