# Development tool, never shipped. tools/screenshot.sh installs and removes it.
#
# Binds L3 + R3 together to a screenshot. gptokeyb2 sends F9 only while both
# stick clicks are held, and mkxp-z resolves :F9 through SDL_GetScancodeFromName,
# since RGSS itself has no F keys.
#
# Frames land in screenshots/ next to the engine, at the game's own 640x480.

module Graphics
  class << self
    unless method_defined?(:_shot_update) || private_method_defined?(:_shot_update)
      alias_method :_shot_update, :update

      SHOT_DIR = 'screenshots'
      begin
        Dir.mkdir(SHOT_DIR) unless File.directory?(SHOT_DIR)
      rescue SystemCallError
      end

      def _shot_next_path
        n = 1
        n += 1 while File.exist?(format('%s/shot_%03d.png', SHOT_DIR, n))
        format('%s/shot_%03d.png', SHOT_DIR, n)
      end

      def update
        _shot_update
        begin
          held = Input.press?(:F9)
          if held && !@_shot_held
            Dir.mkdir(SHOT_DIR) unless File.directory?(SHOT_DIR)
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
