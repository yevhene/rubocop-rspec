# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for `let` definitions that come after an example.
      #
      # @example
      #   # Bad
      #   let(:foo) { bar }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   let(:some) { other }
      #
      #   it 'checks what some does' do
      #     expect(some).to be
      #   end
      #
      #   # Good
      #   let(:foo) { bar }
      #   let(:some) { other }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   it 'checks what some does' do
      #     expect(some).to be
      #   end
      class LetBeforeExamples < Cop
        MSG = 'Move `let` before the examples in the group.'.freeze

        def_node_matcher :let?, '(block (send nil {:let :let!} ...) ...)'
        def_node_matcher :example_or_group?, <<-PATTERN
          {
            #{(Examples::ALL + ExampleGroups::ALL).block_pattern}
            #{Includes::EXAMPLES.send_pattern}
          }
        PATTERN

        def on_block(node)
          return unless example_group_with_body?(node)

          check_let_declarations(node.body) if multiline_block?(node.body)
        end

        def autocorrect(node)
          lambda do |corrector|
            first_example = find_first_example(node)
            first_example_pos = first_example.loc.expression
            indent = "\n" + ' ' * first_example.loc.column
            corrector.insert_before(first_example_pos, source(node) + indent)
            corrector.remove(node_range_with_surrounding_space(node))
          end
        end

        private

        def multiline_block?(block)
          block.begin_type?
        end

        def check_let_declarations(node)
          example_found = false

          node.each_child_node do |child|
            if let?(child)
              add_offense(child, :expression) if example_found
            elsif example_or_group?(child)
              example_found = true
            end
          end
        end

        def find_first_example(node)
          node.parent.children.find { |sibling| example_or_group?(sibling) }
        end

        def node_range(node)
          range_between(node.loc.expression.begin_pos, last_node_loc(node))
        end

        def node_range_with_surrounding_space(node)
          range = node_range(node)
          range = range_with_surrounding_space(range, :left, false)
          range = range_with_surrounding_space(range, :right, true)
          range
        end

        def source(node)
          node_range(node).source
        end

        def last_node_loc(node)
          last_line = node.loc.end.line
          heredoc_line(node) do |loc|
            return loc.end_pos if loc.line > last_line
          end
          node.loc.end.end_pos
        end

        def heredoc_line(node, &block)
          yield node.loc.heredoc_end if node.loc.respond_to?(:heredoc_end)

          node.each_child_node { |child| heredoc_line(child, &block) }
        end
      end
    end
  end
end
