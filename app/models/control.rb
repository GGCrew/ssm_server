class Control < ActiveRecord::Base


	def self.default_attributes
		control = Control.last

		control = Control.create!(
			hold_duration: 10 * 1000,
			transition_duration: 3 * 1000,
			transition_type: 'dissolve',
			play_state: 'play',
			auto_approve: false,
			effect_normal: true,
			effect_grayscale: false,
			effect_sepia: false,
			apply_vignette: false
		) unless control

		attributes = {
			hold_duration:				(control.hold_duration				? control.hold_duration				: 10 * 1000),
			transition_duration:	(control.transition_duration	? control.transition_duration	: 3 * 1000),
			transition_type:			(control.transition_type			? control.transition_type			: 'dissolve'),
			play_state:						(control.play_state						? control.play_state					: 'play'),
			auto_approve:					(control.auto_approve					? control.auto_approve				: false),
			effect_normal:				(!control.effect_normal.nil?	? control.effect_normal				: true),
			effect_grayscale:			(control.effect_grayscale			? control.effect_grayscale		: false),
			effect_sepia:					(control.effect_sepia					? control.effect_sepia				: false),
			apply_vignette:				(control.apply_vignette				? control.apply_vignette			: false)
		}

		return attributes
	end


end
