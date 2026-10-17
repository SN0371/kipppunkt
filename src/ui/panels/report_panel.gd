class_name ReportPanel
extends SidePanel
## Quarterly report: what happened in the last resolved turn.


## Fills the content.
func build() -> void:
	if session.last_report.is_empty():
		content.add_child(UiKit.hint(tr("ui.report.empty")))
		return
	for entry in session.last_report:
		var text := LogFormatter.format(entry, session.defs)
		if not text.is_empty():
			content.add_child(UiKit.label("• " + text))
