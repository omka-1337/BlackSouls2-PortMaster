# Development tool, never shipped. tools/screenshot.sh installs and removes it.
#
# Binds L2 to a screenshot. gptokeyb2 maps L2 to F9, and mkxp-z resolves :F9
# through SDL_GetScancodeFromName, so the key is read directly rather than
# through an RGSS input constant, which has no F keys here.
#
# Frames land next to the engine as screenshot_001.png and upward, at the game's
# own 640x480.

module Graphics
  class << self
    unless method_defined?(:_shot_update) || private_method_defined?(:_shot_update)
      alias_method :_shot_update, :update

      def _shot_next_path
        n = 1
        n += 1 while File.exist?(format('screenshot_%03d.png', n))
        format('screenshot_%03d.png', n)
      end

      def update
        _shot_update
        begin
          held = Input.press?(:F9)
          if held && !@_shot_held
            path = _shot_next_path
            Graphics.screenshot(path)
            puts "[screenshot] saved #{path}"
          end
          @_shot_held = held
        rescue => e
          puts "[screenshot] failed: #{e.class}: #{e.message}" unless @_shot_warned
          @_shot_warned = true
        end
      end
    end
  end
end
