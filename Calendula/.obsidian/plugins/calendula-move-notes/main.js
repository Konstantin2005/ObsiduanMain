const { Plugin, Setting, Notice, TFile, PluginSettingTab } = require('obsidian');

// ===== SETTINGS =====
const DEFAULT_SETTINGS = {
	basePath: '',
	year: new Date().getFullYear(),
	dryRun: false,
	categories: [
		{ name: 'Личное', filter: '*Личное*',  dest: 'Вечно зеленные действия', enabled: true, movedTotal: 0 },
		{ name: 'Соц',    filter: '*Соц*',     dest: 'CRM',                     enabled: true, movedTotal: 0 },
		{ name: 'Мысли',  filter: '*Мысли*',   dest: 'Маслины',                  enabled: true, movedTotal: 0 },
	]
};

// ===== PLUGIN =====
class CalendulaMoveNotesPlugin extends Plugin {
	async onload() {
		await this.loadSettings();

		// Auto-detect basePath if empty (use vault root)
		if (!this.settings.basePath) {
			this.settings.basePath = this.app.vault.adapter.getBasePath() || '';
			await this.saveSettings();
		}

		// Register commands — bindable to hotkeys in Settings → Hotkeys
		this.addCommand({
			id: 'move-diary-notes',
			name: 'Перенести заметки: Личное → Вечно зеленные, Соц → Соц Капитал, Мысли → Маслины',
			icon: 'arrow-right-from-line',
			callback: () => this.runMove(false),
		});

		this.addCommand({
			id: 'move-diary-notes-dry',
			name: 'Просмотр (dry-run): показать что будет перенесено',
			icon: 'eye',
			callback: () => this.runMove(true),
		});

		// Settings tab
		this.addSettingTab(new CalendulaMoveNotesSettingTab(this.app, this));
	}

	async loadSettings() {
		this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
	}

	async saveSettings() {
		await this.saveData(this.settings);
	}

	async runMove(dryRun) {
		const { basePath, year, categories } = this.settings;
		const sourceRelDir = `Calendula/${year}`;
		const vault = this.app.vault;

		// Check source exists
		const sourceFolder = vault.getAbstractFileByPath(sourceRelDir);
		if (!sourceFolder) {
			new Notice(`❌ Папка не найдена: ${sourceRelDir}\nПроверьте базовый путь в настройках.`, 6000);
			return;
		}

		const notice = new Notice('🔄 Перенос заметок...', 0);
		let totalMoved = 0;
		let totalSkipped = 0;
		let totalErrors = 0;
		const results = [];

		for (const cat of categories) {
			if (!cat.enabled) {
				results.push({ name: cat.name, moved: 0, errors: 0, skipped: 0, status: '⏭️' });
				continue;
			}

			const files = this.findFilesByPattern(sourceRelDir, cat.filter);
			const filled = files.filter(f => f.stat.size > 0);
			const empty  = files.filter(f => f.stat.size === 0);

			let moved = 0;
			let errors = 0;

			if (!dryRun) {
				for (const file of filled) {
					try {
						// Relative path from source dir
						const relPath = file.path.substring(sourceRelDir.length + 1);
						const destRelDir = `${cat.dest}/${year}`;
						const destPath = `${destRelDir}/${relPath}`;

						// Ensure parent folder exists
						const parentPath = destPath.substring(0, destPath.lastIndexOf('/'));
						const parentFolder = vault.getAbstractFileByPath(parentPath);
						if (!parentFolder) {
							await vault.createFolder(parentPath);
						}

						// Rename (move) the file
						await vault.rename(file, destPath);
						moved++;
					} catch (err) {
						console.error(`[CalendulaMoveNotes] Error: ${file.path}`, err);
						errors++;
					}
				}
				totalMoved += moved;
			} else {
				moved = filled.length;
			}

			totalSkipped += empty.length;
			totalErrors += errors;
			results.push({ name: cat.name, moved, errors, skipped: empty.length, status: errors > 0 ? '⚠️' : '✅' });

			// Update total stats
			if (!dryRun) {
				cat.movedTotal = (cat.movedTotal || 0) + moved;
			}
		}

		if (!dryRun) {
			await this.saveSettings();
		}

		notice.hide();

		// Build result message
		let msg = dryRun ? '🔍 DRY-RUN — будет перенесено:\n' : '✅ Перенос завершён!\n';
		for (const r of results) {
			msg += `\n${r.status} ${r.name}: ${r.moved} файлов`;
			if (r.errors > 0) msg += `, ${r.errors} ошибок`;
			if (r.skipped > 0) msg += ` (пустых: ${r.skipped})`;
		}

		new Notice(msg, 8000);
		console.log(`[CalendulaMoveNotes] ${dryRun ? 'DRY-RUN' : 'MOVE'} completed: ${totalMoved} moved, ${totalErrors} errors, ${totalSkipped} skipped`);
	}

	/**
	 * Find all files in a directory (recursive) matching a simple glob pattern
	 * Supports patterns like: *Личное*, *Соц*, *Мысли*
	 */
	findFilesByPattern(dirPath, pattern) {
		const searchTerm = pattern.replace(/\*/g, '').toLowerCase();
		const result = [];

		const walk = (folder) => {
			if (!folder.children) return;
			for (const child of folder.children) {
				if (child.children) {
					// It's a folder — recurse
					walk(child);
				} else if (child instanceof TFile) {
					// Match by name
					if (child.name.toLowerCase().contains(searchTerm)) {
						result.push(child);
					}
				}
			}
		};

		const root = this.app.vault.getAbstractFileByPath(dirPath);
		if (root) walk(root);
		return result;
	}
}

// ===== SETTINGS TAB =====
class CalendulaMoveNotesSettingTab extends PluginSettingTab {
	constructor(app, plugin) {
		super(app, plugin);
		this.plugin = plugin;
	}

	display() {
		const { containerEl } = this;
		containerEl.empty();

		containerEl.createEl('h1', { text: '📋 Calendula Move Notes' });
		containerEl.createEl('p', {
			text: 'Перенос заметок из дневника в целевые графы. Настройте правила ниже и назначьте горячую клавишу в Settings → Hotkeys.',
			cls: 'setting-item-description'
		});

		// --- Base path (read-only, auto-detected) ---
		new Setting(containerEl)
			.setName('📁 Базовый путь хранилища')
			.setDesc('Автоматически определяется как корень vault. Если нужно изменить — укажите вручную.')
			.addText(text => text
				.setPlaceholder('auto')
				.setValue(this.plugin.settings.basePath)
				.onChange(async (value) => {
					this.plugin.settings.basePath = value;
					await this.plugin.saveSettings();
				}));

		// --- Year ---
		new Setting(containerEl)
			.setName('📅 Год')
			.setDesc('Какой год обрабатывать')
			.addText(text => text
				.setPlaceholder('2026')
				.setValue(String(this.plugin.settings.year))
				.onChange(async (value) => {
					const num = parseInt(value);
					if (!isNaN(num) && num > 2000 && num < 2100) {
						this.plugin.settings.year = num;
						await this.plugin.saveSettings();
					}
				}));

		containerEl.createEl('hr');

		// --- Categories ---
		containerEl.createEl('h2', { text: '📦 Категории' });
		containerEl.createEl('p', {
			text: 'Каждая категория — это правило: файл, имя которого содержит фильтр, переносится в указанную папку.',
			cls: 'setting-item-description'
		});

		for (let i = 0; i < this.plugin.settings.categories.length; i++) {
			const cat = this.plugin.settings.categories[i];
			const idx = i;

			const section = containerEl.createDiv();
			section.addClass('calendula-category-section');

			// Header with name and toggle
			new Setting(section)
				.setName(cat.name)
				.setDesc('Включить/выключить категорию')
				.addToggle(toggle => toggle
					.setValue(cat.enabled)
					.onChange(async (value) => {
						this.plugin.settings.categories[idx].enabled = value;
						await this.plugin.saveSettings();
						this.display();
					}));

			// Filter pattern
			new Setting(section)
				.setName('🔍 Фильтр')
				.setDesc('Шаблон имени (например: *Личное*)')
				.addText(text => text
					.setValue(cat.filter)
					.onChange(async (value) => {
						this.plugin.settings.categories[idx].filter = value;
						await this.plugin.saveSettings();
					}));

			// Destination folder
			new Setting(section)
				.setName('📂 Папка назначения')
				.setDesc('Относительный путь от корня vault')
				.addText(text => text
					.setValue(cat.dest)
					.onChange(async (value) => {
						this.plugin.settings.categories[idx].dest = value;
						await this.plugin.saveSettings();
					}));

			// Delete button
			new Setting(section)
				.setName('Удалить категорию')
				.setDesc('')
				.addButton(btn => btn
					.setButtonText('🗑️ Удалить')
					.onClick(async () => {
						this.plugin.settings.categories.splice(idx, 1);
						await this.plugin.saveSettings();
						this.display();
					}));

			// Stats
			section.createEl('div', {
				text: `📊 Перенесено за всё время: ${cat.movedTotal || 0} файлов`,
				attr: { style: 'color: var(--text-muted); font-size: 0.85em; margin: 4px 0 12px 20px;' }
			});
		}

		// Add category button
		new Setting(containerEl)
			.setName('➕ Добавить категорию')
			.setDesc('Создать новое правило переноса')
			.addButton(btn => btn
				.setButtonText('+ Добавить')
				.setCta()
				.onClick(async () => {
					this.plugin.settings.categories.push({
						name: 'Новая категория',
						filter: '*Запрос*',
						dest: 'Новая папка',
						enabled: true,
						movedTotal: 0
					});
					await this.plugin.saveSettings();
					this.display();
				}));

		containerEl.createEl('hr');

		// --- Run buttons ---
		containerEl.createEl('h2', { text: '🚀 Запуск' });

		new Setting(containerEl)
			.setName('▶️ Перенести заметки')
			.setDesc('Запустить перемещение по настроенным правилам')
			.addButton(btn => btn
				.setButtonText('▶️ Выполнить')
				.setCta()
				.onClick(() => {
					this.plugin.runMove(false);
				}));

		new Setting(containerEl)
			.setName('🔍 Предпросмотр (dry-run)')
			.setDesc('Показать что будет перенесено без реального перемещения')
			.addButton(btn => btn
				.setButtonText('🔍 Предпросмотр')
				.onClick(() => {
					this.plugin.runMove(true);
				}));

		// --- Hotkey hint ---
		containerEl.createEl('div', {
			text: '⌨️ Назначьте горячие клавиши: Settings → Hotkeys → найдите "Calendula Move Notes"',
			attr: { style: 'color: var(--text-muted); font-size: 0.85em; text-align: center; margin-top: 2em; padding: 12px; border-top: 1px solid var(--background-modifier-border);' }
		});
	}
}

module.exports = CalendulaMoveNotesPlugin;
