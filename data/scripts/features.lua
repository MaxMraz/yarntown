-- Sets up all non built-in gameplay features specific to this quest.

-- Usage: require("scripts/features")

-- Features can be enabled to disabled independently by commenting
-- or uncommenting lines below.

require"scripts/action/hole_drop_landing"
require("scripts/hud/hud")
require("scripts/menus/dialog_box")
require"scripts/meta/camera"
require"scripts/meta/enemy"
require"scripts/meta/hero"
require("scripts/meta/item")
require"scripts/meta/map"
require"scripts/meta/switch"

return true
