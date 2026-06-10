const { Plugin, PluginSettingTab, Setting, Notice, requestUrl } = require("obsidian");

const DEFAULT_SETTINGS = {
	webhookUrl: "",
	titlePrefix: "Obsidian note",
	footer: "",
	delayMs: 350,
};

function chunkText(text, maxLength) {
	const lines = text.split(/\r?\n/);
	const chunks = [];
	let current = "";

	for (const line of lines) {
		const candidate = current.length === 0 ? line : `${current}\n${line}`;

		if (candidate.length <= maxLength) {
			current = candidate;
			continue;
		}

		if (current.length > 0) {
			chunks.push(current);
			current = "";
		}

		if (line.length <= maxLength) {
			current = line;
			continue;
		}

		for (let offset = 0; offset < line.length; offset += maxLength) {
			chunks.push(line.slice(offset, offset + maxLength));
		}
	}

	if (current.length > 0) {
		chunks.push(current);
	}

	return chunks;
}

async function sleep(ms) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

class DiscordSendActiveNoteSettingTab extends PluginSettingTab {
	constructor(app, plugin) {
		super(app, plugin);
		this.plugin = plugin;
	}

	display() {
		const { containerEl } = this;
		containerEl.empty();

		containerEl.createEl("h2", { text: "Discord Send Active Note" });

		new Setting(containerEl)
			.setName("Webhook URL")
			.setDesc("Discord webhook for the target channel.")
			.addText((text) =>
				text
					.setPlaceholder("https://discord.com/api/webhooks/...")
					.setValue(this.plugin.settings.webhookUrl)
					.onChange(async (value) => {
						this.plugin.settings.webhookUrl = value.trim();
						await this.plugin.saveSettings();
					}),
			);

		new Setting(containerEl)
			.setName("Title prefix")
			.setDesc("Shown at the top of each Discord message.")
			.addText((text) =>
				text
					.setValue(this.plugin.settings.titlePrefix)
					.onChange(async (value) => {
						this.plugin.settings.titlePrefix = value;
						await this.plugin.saveSettings();
					}),
			);

		new Setting(containerEl)
			.setName("Footer")
			.setDesc("Optional extra line appended to each chunk.")
			.addText((text) =>
				text
					.setValue(this.plugin.settings.footer)
					.onChange(async (value) => {
						this.plugin.settings.footer = value;
						await this.plugin.saveSettings();
					}),
			);

		new Setting(containerEl)
			.setName("Delay between messages")
			.setDesc("Milliseconds between Discord requests.")
			.addText((text) =>
				text
					.setValue(String(this.plugin.settings.delayMs))
					.onChange(async (value) => {
						const parsed = Number.parseInt(value, 10);
						this.plugin.settings.delayMs = Number.isFinite(parsed) && parsed >= 0 ? parsed : 350;
						await this.plugin.saveSettings();
					}),
			);
	}
}

module.exports = class DiscordSendActiveNotePlugin extends Plugin {
	async onload() {
		await this.loadSettings();

		this.addCommand({
			id: "send-active-note-to-discord",
			name: "Send active note to Discord",
			callback: async () => {
				await this.sendActiveNote();
			},
		});

		this.addSettingTab(new DiscordSendActiveNoteSettingTab(this.app, this));
	}

	async sendActiveNote() {
		const file = this.app.workspace.getActiveFile();
		if (!file) {
			new Notice("No active note found.");
			return;
		}

		if (!this.settings.webhookUrl) {
			new Notice("Set the Discord webhook URL in plugin settings first.");
			return;
		}

		const text = await this.app.vault.read(file);
		if (!text || !text.trim()) {
			new Notice("Active note is empty.");
			return;
		}

		const chunks = chunkText(text, 1800);
		const total = chunks.length;

		for (let i = 0; i < total; i++) {
			const header = `**${this.settings.titlePrefix}** [${i + 1}/${total}]`;
			let content = `${header}\n${chunks[i]}`;
			if (this.settings.footer) {
				content += `\n${this.settings.footer}`;
			}

			await requestUrl({
				url: this.settings.webhookUrl,
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({ content }),
			});

			if (this.settings.delayMs > 0 && i < total - 1) {
				await sleep(this.settings.delayMs);
			}
		}

		new Notice(`Sent ${total} Discord message${total === 1 ? "" : "s"}.`);
	}

	async loadSettings() {
		this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
	}

	async saveSettings() {
		await this.saveData(this.settings);
	}
};
