class_name MediaPanel
extends SidePanel
## Overview of all media houses and how they report on the party (rechenmodell.md 5.6).


## Fills the content.
func build() -> void:
	var state := session.state
	var defs := session.defs
	var tones := MediaSystem.tones(state, defs, IdeologySystem.profile(state.party, defs))
	content.add_child(UiKit.hint(tr("ui.media.hint")))
	content.add_child(UiKit.label(tr("ui.media.national_climate") % state.media_climate))
	for media_id: String in defs.media:
		var house := state.media[media_id]
		content.add_child(UiKit.heading(tr(media_id + ".name")))
		content.add_child(UiKit.grid([
			[tr("ui.media.reach"), UiKit.score(house.reach)],
			[tr("ui.media.credibility"), UiKit.score(house.credibility)],
			[tr("ui.media.independence"), UiKit.score(house.independence)],
			[tr("ui.media.tone"), "%+.2f" % tones[media_id]],
		]))
