# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryGirl
        # Prefer using create_list over n.times { create :obj } calls.
        #
        # @example
        #   # bad
        #   3.times { create :user }
        #
        #   # good
        #   create_list :user, 3
        #
        #   # good
        #   3.times { |n| create :user, created_at: n.months.ago }
        class CreateList < Cop
          MSG = 'Prefer create_list.'.freeze

          def_node_matcher :n_times, '(send (int $_) :times)'

          def_node_matcher :times_block_without_args?, <<-PATTERN
            (block
              #n_times
              (args)
              ...
            )
          PATTERN

          def_node_matcher :factory_call, <<-PATTERN
            (send ${(const nil :FactoryGirl) nil} :create (sym $_) $...)
          PATTERN

          def on_block(node)
            return unless times_block_without_args?(node)

            receiver, _args, body = *node

            return unless factory_call(body)

            add_offense(receiver, :expression)
          end

          def autocorrect(node)
            block = node.parent
            replacement = generate_replacement(block)
            lambda do |corrector|
              corrector.replace(block.loc.expression, replacement)
            end
          end

          private

          def generate_replacement(block)
            receiver, _args, body = *block
            count = n_times(receiver)
            factory_call_replacement(body, count)
          end

          def method_uses_parens?(node)
            return false unless node.location.begin && node.location.end
            node.location.begin.source == '(' && node.location.end.source == ')'
          end

          def factory_call_replacement(body, count)
            receiver, factory, options = *factory_call(body)

            replacement = ''
            replacement += "#{receiver.source}." if receiver

            arguments = ":#{factory}, #{count}"
            options.each do |option|
              arguments += ", #{option.source}"
            end

            replacement += format_method_call(body, arguments)
            replacement
          end

          def format_method_call(node, arguments)
            if method_uses_parens?(node)
              "create_list(#{arguments})"
            else
              "create_list #{arguments}"
            end
          end
        end
      end
    end
  end
end
