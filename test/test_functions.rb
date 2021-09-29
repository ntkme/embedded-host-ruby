# frozen_string_literal: true

require_relative 'helper'

module Sass
  class Embedded
    class FunctionsTest < MiniTest::Test
      def setup
        @embedded = Embedded.new
      end

      def teardown
        @embedded.close
      end

      # rubocop:disable Layout/LineLength

      def render(sass)
        @embedded.render(data: sass,
                         functions: {
                           'javascript_path($path)': lambda { |path|
                             path.string.text = "/js/#{path.string.text}"
                             path
                           },
                           'stylesheet_path($path)': lambda { |path|
                                                       path.string.text = "/css/#{path.string.text}"
                                                       path
                                                     },
                           'sass_return_path($path)': lambda { |path|
                                                        path
                                                      },
                           'no_return_path($path)': lambda { |_path|
                                                      EmbeddedProtocol::Value.new(
                                                        singleton: EmbeddedProtocol::SingletonValue::NULL
                                                      )
                                                    },
                           'optional_arguments($path, $optional: null)': lambda { |path, optional|
                                                                           EmbeddedProtocol::Value.new(
                                                                             string: EmbeddedProtocol::Value::String.new(
                                                                               text: "#{path.string.text}/#{optional.singleton == :NULL ? 'bar' : optional.string.text}",
                                                                               quoted: true
                                                                             )
                                                                           )
                                                                         },
                           'function_that_raises_errors()': lambda {
                                                              raise StandardError,
                                                                    'Intentional wrong thing happened somewhere inside the custom function'
                                                            },
                           'nice_color_argument($color)': lambda { |color|
                                                            color
                                                          },
                           'returns_a_color()': lambda {
                                                  EmbeddedProtocol::Value.new(
                                                    rgb_color: EmbeddedProtocol::Value::RgbColor.new(
                                                      red: 0,
                                                      green: 0,
                                                      blue: 0,
                                                      alpha: 1
                                                    )
                                                  )
                                                },
                           'returns_a_number()': lambda {
                                                   EmbeddedProtocol::Value.new(
                                                     number: EmbeddedProtocol::Value::Number.new(
                                                       value: -312,
                                                       numerators: ['rem']
                                                     )
                                                   )
                                                 },
                           'returns_a_bool()': lambda {
                                                 EmbeddedProtocol::Value.new(
                                                   singleton: EmbeddedProtocol::SingletonValue::TRUE
                                                 )
                                               },
                           'inspect_bool($argument)': lambda { |argument|
                                                        unless argument&.singleton == :TRUE || argument.singleton == :FALSE
                                                          raise StandardError,
                                                                'passed value is not a EmbeddedProtocol::SingletonValue::TRUE or EmbeddedProtocol::SingletonValue::FALSE'
                                                        end

                                                        argument
                                                      },
                           'inspect_number($argument)': lambda { |argument|
                                                          unless argument&.number.is_a? EmbeddedProtocol::Value::Number
                                                            raise StandardError,
                                                                  'passed value is not a EmbeddedProtocol::Value::Number'
                                                          end

                                                          argument
                                                        },
                           'inspect_map($argument)': lambda { |argument|
                                                       unless argument&.map.is_a? EmbeddedProtocol::Value::Map
                                                         raise StandardError,
                                                               'passed value is not a EmbeddedProtocol::Value::Map'
                                                       end

                                                       argument
                                                     },
                           'inspect_list($argument)': lambda { |argument|
                                                        unless argument&.list.is_a? EmbeddedProtocol::Value::List
                                                          raise StandardError,
                                                                'passed value is not a EmbeddedProtocol::Value::List'
                                                        end

                                                        argument
                                                      },
                           'inspect_argument_list($args...)': lambda { |args|
                                                                unless args.argument_list.is_a? EmbeddedProtocol::Value::ArgumentList
                                                                  raise StandardError,
                                                                        'passed value is not a EmbeddedProtocol::Value::ArgumentList'
                                                                end

                                                                args
                                                              },
                           'returns_sass_value()': lambda {
                                                     EmbeddedProtocol::Value.new(
                                                       rgb_color: EmbeddedProtocol::Value::RgbColor.new(
                                                         red: 0,
                                                         green: 0,
                                                         blue: 0,
                                                         alpha: 1
                                                       )
                                                     )
                                                   },
                           'returns_sass_map()': lambda {
                                                   EmbeddedProtocol::Value.new(
                                                     map: EmbeddedProtocol::Value::Map.new(
                                                       entries: [
                                                         EmbeddedProtocol::Value::Map::Entry.new(
                                                           key: EmbeddedProtocol::Value.new(
                                                             string: EmbeddedProtocol::Value::String.new(
                                                               text: 'color',
                                                               quoted: true
                                                             )
                                                           ),
                                                           value: EmbeddedProtocol::Value.new(
                                                             rgb_color: EmbeddedProtocol::Value::RgbColor.new(
                                                               red: 0,
                                                               green: 0,
                                                               blue: 0,
                                                               alpha: 1
                                                             )
                                                           )
                                                         )
                                                       ]
                                                     )
                                                   )
                                                 },
                           'returns_sass_list()': lambda {
                                                    EmbeddedProtocol::Value.new(
                                                      list: EmbeddedProtocol::Value::List.new(
                                                        separator: EmbeddedProtocol::ListSeparator::COMMA,
                                                        has_brackets: true,
                                                        contents: [
                                                          EmbeddedProtocol::Value.new(
                                                            number: EmbeddedProtocol::Value::Number.new(
                                                              value: 10
                                                            )
                                                          ),
                                                          EmbeddedProtocol::Value.new(
                                                            number: EmbeddedProtocol::Value::Number.new(
                                                              value: 20
                                                            )
                                                          ),
                                                          EmbeddedProtocol::Value.new(
                                                            number: EmbeddedProtocol::Value::Number.new(
                                                              value: 30
                                                            )
                                                          )
                                                        ]
                                                      )
                                                    )
                                                  }
                         }).css
      end

      # rubocop:enable Layout/LineLength

      def test_functions_may_return_sass_string_type
        assert_sass <<-SCSS, <<-CSS
          div { url: url(sass_return_path("foo.svg")); }
        SCSS
          div { url: url("foo.svg"); }
        CSS
      end

      def test_functions_work_with_varying_quotes_and_string_types
        assert_sass <<-SCSS, <<-CSS
          div {
            url: url(asset-path("foo.svg"));
            url: url(image-path("foo.png"));
            url: url(video-path("foo.mov"));
            url: url(audio-path("foo.mp3"));
            url: url(font-path("foo.woff"));
            url: url(javascript-path('foo.js'));
            url: url(javascript-path("foo.js"));
            url: url(stylesheet-path("foo.css"));
          }
        SCSS
          div {
            url: url(asset-path("foo.svg"));
            url: url(image-path("foo.png"));
            url: url(video-path("foo.mov"));
            url: url(audio-path("foo.mp3"));
            url: url(font-path("foo.woff"));
            url: url("/js/foo.js");
            url: url("/js/foo.js");
            url: url("/css/foo.css");
          }
        CSS
      end

      def test_function_with_empty_unquoted_string
        assert_sass <<-SCSS, <<-CSS
          div {url: url(no-return-path('foo.svg'));}
        SCSS
          div { url: url(); }
        CSS
      end

      def test_function_that_returns_a_color
        assert_sass <<-SCSS, <<-CSS
          div { background: returns-a-color(); }
        SCSS
          div { background: black; }
        CSS
      end

      def test_function_that_returns_a_number
        assert_sass <<-SCSS, <<-CSS
          div { width: returns-a-number(); }
        SCSS
          div { width: -312rem; }
        CSS
      end

      def test_function_that_takes_a_number
        assert_sass <<-SCSS, <<-CSS
          div { display: inspect-number(42.1px); }
        SCSS
          div { display: 42.1px; }
        CSS
      end

      def test_function_that_returns_a_bool
        assert_sass <<-SCSS, <<-CSS
          div { width: returns-a-bool(); }
        SCSS
          div { width: true; }
        CSS
      end

      def test_function_that_takes_a_bool
        assert_sass <<-SCSS, <<-CSS
          div { display: inspect-bool(true)}
        SCSS
          div { display: true; }
        CSS
      end

      def test_function_with_optional_arguments
        assert_sass <<-SCSS, <<-EXPECTED_CSS
          div {
            url: optional_arguments('first');
            url: optional_arguments('second', 'qux');
          }
        SCSS
          div {
            url: "first/bar";
            url: "second/qux";
          }
        EXPECTED_CSS
      end

      def test_functions_may_accept_sass_color_type
        assert_sass <<-SCSS, <<-EXPECTED_CSS
          div { color: nice_color_argument(red); }
        SCSS
          div { color: red; }
        EXPECTED_CSS
      end

      def test_function_with_error
        assert_raises(RenderError) do
          render('div {url: function_that_raises_errors();}')
        end
      end

      def test_function_that_returns_a_sass_value
        assert_sass <<-SCSS, <<-CSS
          div { background: returns-sass-value(); }
        SCSS
          div { background: black; }
        CSS
      end

      def test_function_that_returns_a_sass_map
        assert_sass <<-SCSS, <<-CSS
          $my-map: returns-sass-map();
          div { background: map-get( $my-map, color ); }
        SCSS
          div { background: black; }
        CSS
      end

      def test_function_that_takes_a_sass_map
        assert_sass <<-SCSS, <<-CSS
          div { background-color: map-get( inspect-map(( color: black, number: 1.23px, string: "abc", map: ( x: 'y' ))), color ); }
        SCSS
          div { background-color: black; }
        CSS
      end

      def test_function_that_returns_a_sass_list
        assert_sass <<-SCSS, <<-CSS
          $my-list: returns-sass-list();
          div { width: nth( $my-list, 2 ); }
        SCSS
          div { width: 20; }
        CSS
      end

      def test_function_that_takes_a_sass_list
        assert_sass <<-SCSS, <<-CSS
          div { width: nth(inspect-list((10 20 30)), 2); }
        SCSS
          div { width: 20; }
        CSS
      end

      def test_function_that_takes_a_sass_argument_list
        assert_sass <<-SCSS, <<-CSS
          @use "sass:meta";

          @each $name, $color in meta.keywords(inspect-argument-list(
            $string: #080,
            $comment: #800,
            $variable: #60b,
          )) {
            pre span.stx-\#{$name} {
              color: $color;
            }
          }
        SCSS
          pre span.stx-string {
            color: #080;
          }
          pre span.stx-comment {
            color: #800;
          }
          pre span.stx-variable {
            color: #60b;
          }
        CSS
      end

      def test_concurrency
        10.times do
          threads = []
          10.times do |i|
            threads << Thread.new(i) do |id|
              output = @embedded.render(data: 'div { url: test-function() }',
                                        functions: {
                                          'test_function()': lambda {
                                            EmbeddedProtocol::Value.new(
                                              string: EmbeddedProtocol::Value::String.new(
                                                text: "thread-#{id}",
                                                quoted: true
                                              )
                                            )
                                          }
                                        }).css
              assert_match(/url: "thread-#{id}"/, output)
            end
          end
          threads.each(&:join)
        end
      end

      def test_pass_custom_functions_as_a_parameter
        output = @embedded.render(data: 'div { url: test-function(); }',
                                  functions: {
                                    'test_function()': lambda {
                                      EmbeddedProtocol::Value.new(
                                        string: EmbeddedProtocol::Value::String.new(
                                          text: 'custom_function',
                                          quoted: true
                                        )
                                      )
                                    }
                                  }).css

        assert_match(/custom_function/, output)
      end

      def test_pass_incompatible_type_to_custom_functions
        assert_raises(RenderError) do
          @embedded.render(data: 'div { url: test-function(); }',
                           functions: {
                             'test_function()': lambda {
                               Class.new
                             }
                           }).css
        end
      end

      private

      def assert_sass(sass, expected_css)
        output = render(sass)
        assert_equal expected_css.strip.gsub!(/\s+/, ' '), # poor man's String#squish
                     output.strip.gsub!(/\s+/, ' ')
      end

      def stderr_output
        $stderr.string.gsub("\u0000\n", '').chomp
      end
    end
  end
end
