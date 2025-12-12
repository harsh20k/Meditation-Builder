//
//  L10n.swift
//  Meditation Builder
//
//  Created by harsh on 09/07/25.
//

import Foundation

// MARK: - Localization Keys
enum L10n {
    // MARK: - Tab Bar
    static let tabLibrary = "tab_library"
    static let tabMusic = "tab_music"
    static let tabTimer = "tab_timer"
    static let tabTools = "tab_tools"
    static let tabSettings = "tab_settings"
    
    // MARK: - Main Tab View - Placeholder Views
    static let comingSoon = "coming_soon"
    static let musicDescription = "music_description"
    static let toolsDescription = "tools_description"
    static let settingsDescription = "settings_description"
    
    // MARK: - Routine Library
    static let routineLibraryTitle = "routine_library_title"
    static let searchRoutinesPlaceholder = "search_routines_placeholder"
    static let noRoutinesYet = "no_routines_yet"
    static let noResultsFound = "no_results_found"
    static let createFirstRoutineMessage = "create_first_routine_message"
    static let adjustSearchTermsMessage = "adjust_search_terms_message"
    static let durationFormat = "duration_format"
    static let playRoutineFormat = "play_routine_format"
    static let editRoutineFormat = "edit_routine_format"
    static let moreBlocksFormat = "more_blocks_format"
    static let playerComingSoon = "player_coming_soon"
    static let routinePlayerTitle = "routine_player_title"
    static let playingFormat = "playing_format"
    
    // MARK: - Routine Builder
    static let routineTitle = "routine_title"
    static let totalTimeFormat = "total_time_format"
    static let openingBellLabel = "opening_bell_label"
    static let closingBellLabel = "closing_bell_label"
    static let deleteBlockConfirmation = "delete_block_confirmation"
    static let minutesShort = "minutes_short"
    
    // MARK: - Add Block View
    static let addBlockTitle = "add_block_title"
    static let defaultBlocksTab = "default_blocks_tab"
    static let customBlockTab = "custom_block_tab"
    static let searchBlocksPlaceholder = "search_blocks_placeholder"
    static let blockNamePlaceholder = "block_name_placeholder"
    static let durationLabel = "duration_label"
    static let createCustomBlock = "create_custom_block"
    
    // MARK: - Edit Block View
    static let editBlockTitle = "edit_block_title"
    static let saveButton = "save_button"
    static let durationWithValueFormat = "duration_with_value_format"
    static let openingBellHeader = "opening_bell_header"
    static let openingBellSubtitle = "opening_bell_subtitle"
    
    // MARK: - Bell Picker View
    static let bellPickerTitle = "bell_picker_title"
    static let selectBellMessage = "select_bell_message"
    
    // MARK: - Block Types
    static let blockTypeSilence = "block_type_silence"
    static let blockTypeBreathwork = "block_type_breathwork"
    static let blockTypeChanting = "block_type_chanting"
    static let blockTypeVisualization = "block_type_visualization"
    static let blockTypeBodyScan = "block_type_body_scan"
    static let blockTypeWalking = "block_type_walking"
    static let blockTypeCustom = "block_type_custom"
    
    // MARK: - Bell Types
    static let bellSilent = "bell_silent"
    static let bellSoftBell = "bell_soft_bell"
    static let bellTibetanBowl = "bell_tibetan_bowl"
    static let bellDigitalChime = "bell_digital_chime"
    
    // MARK: - Common Actions
    static let doneButton = "done_button"
    static let cancelButton = "cancel_button"
    static let deleteButton = "delete_button"
    static let editButton = "edit_button"
    static let addButton = "add_button"
    static let backButton = "back_button"
    
    // MARK: - Alert Messages
    static let unsavedChangesTitle = "unsaved_changes_title"
    static let unsavedChangesMessage = "unsaved_changes_message"
    static let discardButton = "discard_button"
    static let saveAndExitButton = "save_and_exit_button"
    
    // MARK: - Error Messages
    static let errorTitle = "error_title"
    static let errorMessage = "error_message"
    static let tryAgainButton = "try_again_button"
    
    // MARK: - Content Types
    static let contentTypeBell = "content_type_bell"
    static let contentTypeAudio = "content_type_audio"
    static let contentTypeVideo = "content_type_video"
    static let contentTypeAmbient = "content_type_ambient"
} 