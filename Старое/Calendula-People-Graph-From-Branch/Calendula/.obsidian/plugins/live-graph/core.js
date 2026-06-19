const createPlugin = require("C:/obsidian/Main/Technical/Scripts/Rendering/live-graph/builtin-graph.js");

function getObsidianExports() {
  try {
    return require("obsidian");
  } catch (error) {
    return null;
  }
}

const obsidian = getObsidianExports();
const hasObsidianApi =
  obsidian &&
  typeof obsidian.ItemView === "function" &&
  typeof obsidian.Plugin === "function" &&
  typeof obsidian.PluginSettingTab === "function" &&
  typeof obsidian.Setting === "function" &&
  typeof obsidian.setIcon === "function" &&
  typeof obsidian.Notice === "function";

module.exports = hasObsidianApi ? createPlugin(obsidian) : createPlugin;
