class Control < ActiveRecord::Base


	def self.default_attributes
		# TODO: created a DEFAULT_ATTRIBUTES constant and iterate/compare to existing values.
		# This should alleviate the following code duplication of default values.

		control = Control.last

		control = Control.create!(
			hold_duration: 10 * 1000,
			transition_duration: 3 * 1000,
			transition_type: 'dissolve',
			play_state: 'play',
			auto_approve: false,
			collect_for_copying: false,
			color_mode_normal: true,
			color_mode_grayscale: false,
			color_mode_sepia: false,
			effect_vignette: false
		) unless control

		attributes = {
			hold_duration:				(control.hold_duration						? control.hold_duration					: 10 * 1000),
			transition_duration:	(control.transition_duration			? control.transition_duration		: 3 * 1000),
			transition_type:			(control.transition_type					? control.transition_type				: 'dissolve'),
			play_state:						(control.play_state								? control.play_state						: 'play'),
			auto_approve:					(control.auto_approve							? control.auto_approve					: false),
			collect_for_copying:	(control.collect_for_copying			? control.collect_for_copying		: false),
			color_mode_normal:		(!control.color_mode_normal.nil?	? control.color_mode_normal			: true),
			color_mode_grayscale:	(control.color_mode_grayscale			? control.color_mode_grayscale	: false),
			color_mode_sepia:			(control.color_mode_sepia					? control.color_mode_sepia			: false),
			effect_vignette:			(control.effect_vignette					? control.effect_vignette				: false)
		}

		return attributes
	end


end
