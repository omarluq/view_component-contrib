# frozen_string_literal: true

require "test_helper"

class StyledComponentTest < ViewTestCase
  class Component < ViewComponentContrib::Base
    include ViewComponentContrib::StyleVariants

    erb_template <<~ERB
      <div class="<%= style(theme: theme, size: size) %>">Hello</div>
    ERB

    style do
      base { %w[flex flex-col] }

      variants {
        theme {
          primary { %w[primary-color primary-bg] }
          secondary { %w[secondary-color secondary-bg] }
        }
        size {
          sm { %w[text-sm] }
          md { %w[text-md] }
          lg { %w[text-lg] }
        }
      }

      defaults { {theme: :primary, size: :sm} }
    end

    attr_reader :theme, :size

    def initialize(theme: :primary, size: :md)
      @theme = theme
      @size = size
    end
  end

  class SubComponent < Component
    erb_template <<~ERB
      <div class="<%= style(:component, theme: theme, size: size) %>">
        Hello
        <a href="#" class="<%= style(mode: mode) %>">Click</a>
      </div>
    ERB

    style do
      base { "cursor-pointer" }

      variants {
        mode {
          light { %w[text-black] }
          dark { %w[text-white] }
        }
      }
    end

    attr_reader :mode

    def initialize(mode: :light, **parent_opts)
      super(**parent_opts)
      @mode = mode
    end
  end

  class PostProccesedComponent < Component
    style_config.postprocess_with do |compiled|
      compiled.join(" ").gsub("primary", "karamba")
    end

    erb_template <<~ERB
      <div class="<%= style("component", theme: theme, size: size) %>">Hello</div>
    ERB
  end

  def test_render_variants
    component = Component.new

    render_inline(component)

    assert_css "div.flex.flex-col.primary-color.primary-bg.text-md"

    component = Component.new(theme: :secondary, size: :md)

    render_inline(component)

    assert_css "div.secondary-color.secondary-bg.text-md"
  end

  def test_render_defaults
    component = Component.new(theme: nil, size: nil)

    render_inline(component)

    assert_css "div.flex.flex-col.primary-color.primary-bg.text-sm"
  end

  def test_inheritance
    component = SubComponent.new(theme: :secondary, size: :lg, mode: :dark)

    render_inline(component)

    assert_css "div.secondary-color.secondary-bg.text-lg"

    assert_css "a.text-white"

    component = SubComponent.new(mode: :light)

    render_inline(component)

    assert_css "a.text-black"
  end

  def test_postprocessor
    component = PostProccesedComponent.new

    render_inline(component)

    assert_css "div.karamba-color.karamba-bg.text-md"
  end
end
