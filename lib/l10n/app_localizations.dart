import 'package:flutter/material.dart';
import 'translations/translations_es.dart';
import 'translations/translations_en.dart';
import 'translations/translations_pt.dart';
import 'translations/translations_fr.dart';
import 'translations/translations_de.dart';
import 'translations/translations_it.dart';
import 'translations/translations_zh.dart';
import 'translations/translations_ja.dart';
import 'translations/translations_ar.dart';
import 'translations/translations_ru.dart';
import 'translations/translations_hi.dart';
import 'translations/translations_ko.dart';

/// Clase principal de localización para la app
class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<void> load() async {
    // Cargar las traducciones según el idioma
    _localizedStrings = _getTranslations(locale.languageCode);
    return;
  }

  Map<String, String> _getTranslations(String languageCode) {
    switch (languageCode) {
      case 'es':
        return translationsES;
      case 'en':
        return translationsEN;
      case 'pt':
        return translationsPT;
      case 'fr':
        return translationsFR;
      case 'de':
        return translationsDE;
      case 'it':
        return translationsIT;
      case 'zh':
        return translationsZH;
      case 'ja':
        return translationsJA;
      case 'ar':
        return translationsAR;
      case 'ru':
        return translationsRU;
      case 'hi':
        return translationsHI;
      case 'ko':
        return translationsKO;
      default:
        return translationsES; // Español por defecto
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Getters para acceso rápido a traducciones comunes

  // App General
  String get appName => translate('app_name');
  String get appSubtitle => translate('app_subtitle');

  // Selector de Idioma
  String get selectLanguage => translate('select_language');
  String get selectLanguageSubtitle => translate('select_language_subtitle');
  String get continueButton => translate('continue');
  String get languageSettings => translate('language_settings');
  String get changeLanguage => translate('change_language');
  String get securitySettings => translate('security_settings');

  // Auth
  String get login => translate('login');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get register => translate('register');
  String get createAccount => translate('create_account');
  String get confirmPassword => translate('confirm_password');
  String get alreadyHaveAccount => translate('already_have_account');
  String get logout => translate('logout');
  String get verifyEmail => translate('verify_email');
  String get welcomeBack => translate('welcome_back');
  String get signUp => translate('sign_up');
  String get resetPassword => translate('reset_password');
  String get sendResetLink => translate('send_reset_link');
  String get backToLogin => translate('back_to_login');
  String get name => translate('name');
  String get enterName => translate('enter_name');
  String get enterEmail => translate('enter_email');
  String get invalidEmail => translate('invalid_email');
  String get enterPassword => translate('enter_password');
  String get passwordMinLength => translate('password_min_length');
  String get passwordsDontMatch => translate('passwords_dont_match');
  String get accountCreated => translate('account_created');
  String get startFree => translate('start_free');
  String get freeVehicle => translate('free_vehicle');
  String get allBasicFeatures => translate('all_basic_features');
  String get noCardRequired => translate('no_card_required');
  String get emailVerificationSent => translate('email_verification_sent');
  String get emailVerifiedSuccessfully =>
      translate('email_verified_successfully');
  String get emailNotVerifiedYet => translate('email_not_verified_yet');
  String get verificationEmailSentTo => translate('verification_email_sent_to');
  String get checkInboxInstructions => translate('check_inbox_instructions');
  String get resendVerificationEmail => translate('resend_verification_email');
  String get verifyYourEmail => translate('verify_your_email');
  String get verifyNow => translate('verify_now');
  String resendCooldown(int seconds) =>
      translate('resend_cooldown').replaceAll('{seconds}', seconds.toString());
  String get autoChecking => translate('auto_checking');
  String get sending => translate('sending');

  // Employee
  String get employeeIdentification => translate('employee_identification');
  String get enterEmployeeNumber => translate('enter_employee_number');
  String get employeeNumber => translate('employee_number');
  String get continueAsManager => translate('continue_as_manager');
  String get requiresPasswordVerification =>
      translate('requires_password_verification');
  String get workingAs => translate('working_as');
  String get workingAsManager => translate('working_as_manager');
  String get changeEmployee => translate('change_employee');
  String get manageEmployees => translate('manage_employees');
  String get addOrManageEmployees => translate('add_or_manage_employees');
  String get employeeMode => translate('employee_mode');
  String get fullAccess => translate('full_access');
  String get managerVerification => translate('manager_verification');
  String get enterPasswordToContinueAsManager =>
      translate('enter_password_to_continue_as_manager');
  String get cancel => translate('cancel');
  String get verify => translate('verify');
  String get couldNotVerifyUser => translate('could_not_verify_user');
  String get welcomeManager => translate('welcome_manager');
  String get incorrectPassword => translate('incorrect_password');
  String get verificationError => translate('verification_error');
  String get enterEmployeeId => translate('enter_employee_id');
  String get invalidEmployeeNumber => translate('invalid_employee_number');
  String get welcome => translate('welcome');
  String get exitApp => translate('exit_app');
  String get exitAppConfirmation => translate('exit_app_confirmation');
  String get exit => translate('exit');
  String get employeeIdHint => translate('employee_id_hint');
  String get employeeAddedSuccessfully =>
      translate('employee_added_successfully');
  String get employeeManagement => translate('employee_management');
  String get newEmployee => translate('new_employee');
  String get addEmployee => translate('add_employee');
  String get yesDelete => translate('yes_delete');

  // Profile
  String get profile => translate('profile');
  String get myProfile => translate('my_profile');
  String get editProfile => translate('edit_profile');
  String get changePassword => translate('change_password');
  String get currentPassword => translate('current_password');
  String get newPassword => translate('new_password');
  String get deleteAccount => translate('delete_account');
  String get completeAllFields => translate('complete_all_fields');
  String get passwordMin6Chars => translate('password_min_6_chars');
  String get passwordChangedSuccessfully =>
      translate('password_changed_successfully');
  String get collectingDownloadingFiles =>
      translate('collecting_downloading_files');

  // Biometric Authentication
  String get biometricAuth => translate('biometric_auth');
  String get enableBiometric => translate('enable_biometric');
  String get disableBiometric => translate('disable_biometric');
  String get biometricEnabled => translate('biometric_enabled');
  String get biometricDisabled => translate('biometric_disabled');
  String get biometricSubtitle => translate('biometric_subtitle');
  String get biometricNotAvailable => translate('biometric_not_available');
  String get biometricNotEnrolled => translate('biometric_not_enrolled');
  String get authenticateBiometric => translate('authenticate_biometric');
  String get authenticateToEnable => translate('authenticate_to_enable');
  String get authenticateToLogin => translate('authenticate_to_login');
  String get biometricError => translate('biometric_error');
  String get biometricSuccess => translate('biometric_success');
  String get loginWithBiometric => translate('login_with_biometric');
  String get biometricAuthFailed => translate('biometric_auth_failed');
  String get biometricAuthSuccessful => translate('biometric_auth_successful');
  String get sessionExpired => translate('session_expired');

  // Vehicles
  String get vehicles => translate('vehicles');
  String get addVehicle => translate('add_vehicle');
  String get searchVehicle => translate('search_vehicle');
  String get vehicleDetails => translate('vehicle_details');
  String get vehicleBrand => translate('vehicle_brand');
  String get vehicleModel => translate('vehicle_model');
  String get vehicleYear => translate('vehicle_year');
  String get vehiclePlate => translate('vehicle_plate');
  String get vehicleColor => translate('vehicle_color');
  String get vehicleVIN => translate('vehicle_vin');
  String get noVehicles => translate('no_vehicles');
  String get tapButtonToAddOne => translate('tap_button_to_add_one');
  String get fleetManagement => translate('fleet_management');
  String get limitReached => translate('limit_reached');
  String get limitReachedMessage => translate('limit_reached_message');
  String get seePlans => translate('see_plans');
  String get vehicleDeleted => translate('vehicle_deleted');
  String get errorDeletingVehicle => translate('error_deleting_vehicle');
  String get uploadingPhoto => translate('uploading_photo');
  String get photoUpdated => translate('photo_updated');
  String get errorUpdatingPhoto => translate('error_updating_photo');
  String get deleteVehicle => translate('delete_vehicle');
  String get deleteVehicleConfirmation =>
      translate('delete_vehicle_confirmation');
  String get edit => translate('edit');
  String get closeSession => translate('close_session');
  String get closeSessionConfirmation =>
      translate('close_session_confirmation');
  String get areYouSure => translate('are_you_sure');
  String get viewPlans => translate('view_plans');
  String get save => translate('save');
  String get mileage => translate('mileage');
  String get status => translate('status');
  String get active => translate('active');
  String get inactive => translate('inactive');
  String get enterBrand => translate('enter_brand');
  String get enterModel => translate('enter_model');
  String get enterYear => translate('enter_year');
  String get enterPlate => translate('enter_plate');
  String get enterVin => translate('enter_vin');
  String get year4Digits => translate('year_4_digits');
  String get newVehicle => translate('new_vehicle');
  String get editVehicle => translate('edit_vehicle');
  String get vehiclePhoto => translate('vehicle_photo');
  String get tapToAddPhoto => translate('tap_to_add_photo');
  String get tapToChangePhoto => translate('tap_to_change_photo');
  String get takePhoto => translate('take_photo');
  String get chooseFromGallery => translate('choose_from_gallery');
  String get vehicleSaved => translate('vehicle_saved');
  String get errorSavingVehicle => translate('error_saving_vehicle');

  // Vehicle Form
  String get vehicleName => translate('vehicle_name');
  String get enterVehicleName => translate('enter_vehicle_name');
  String get pleaseEnterName => translate('please_enter_name');
  String get brand => translate('brand');
  String get model => translate('model');
  String get year => translate('year');
  String get plate => translate('plate');
  String get cameraPermissionNeeded => translate('camera_permission_needed');
  String get errorCapturingPhoto => translate('error_capturing_photo');
  String get warningCouldNotUploadPhoto =>
      translate('warning_could_not_upload_photo');
  String get pleaseEnterYear => translate('please_enter_year');
  String get invalidYear => translate('invalid_year');
  String get pleaseEnterPlate => translate('please_enter_plate');
  String get updateButton => translate('update_button');
  String get saveButton => translate('save_button');
  String get vehicleUpdated => translate('vehicle_updated');
  String get vehicleAdded => translate('vehicle_added');
  String get limitReachedUpgradeMessage =>
      translate('limit_reached_upgrade_message');

  // Vehicle Details
  String get backToFleet => translate('back_to_fleet');
  String get driver => translate('driver');
  String get circulationCardFull => translate('circulation_card_full');
  String get swipeToSeeMore => translate('swipe_to_see_more');

  // Delete Confirmation
  String get logoutTitle => translate('logout_title');
  String get logoutMessage => translate('logout_message');
  String get actionCannotBeUndone => translate('action_cannot_be_undone');
  String get enterCodeToConfirm => translate('enter_code_to_confirm');
  String get enterCode => translate('enter_code');
  String get confirmationCode => translate('confirmation_code');
  String get yourDataIsSafe => translate('your_data_is_safe');

  // Documents
  String get documents => translate('documents');
  String get circulation => translate('circulation');
  String get contract => translate('contract');
  String get addDocument => translate('add_document');
  String get expirationDate => translate('expiration_date');
  String get noExpiration => translate('no_expiration');

  // Maintenance
  String get maintenance => translate('maintenance');
  String get addMaintenance => translate('add_maintenance');
  String get maintenanceType => translate('maintenance_type');
  String get maintenanceDate => translate('maintenance_date');
  String get maintenanceCost => translate('maintenance_cost');
  String get maintenanceNotes => translate('maintenance_notes');
  String get noMaintenance => translate('no_maintenance');

  // Employees
  String get employees => translate('employees');
  String get employeeName => translate('employee_name');
  String get employeeEmail => translate('employee_email');
  String get employeePhone => translate('employee_phone');
  String get noEmployees => translate('no_employees');
  String get selectEmployee => translate('select_employee');

  // Subscription
  String get subscription => translate('subscription');
  String get freePlan => translate('free_plan');
  String get premiumPlan => translate('premium_plan');
  String get upgradeToPremium => translate('upgrade_to_premium');
  String get currentPlan => translate('current_plan');
  String get planFeatures => translate('plan_features');
  String get storage => translate('storage');
  String get backup => translate('backup');
  String get local => translate('local');
  String get cloudStorage => translate('cloud_storage');
  String get manual => translate('manual');
  String get automatic => translate('automatic');
  String get upgradePlan => translate('upgrade_plan');
  String get planFree => translate('plan_free');
  String get planBasic => translate('plan_basic');
  String get planPro => translate('plan_pro');
  String get planEnterprise => translate('plan_enterprise');
  String get idealForStarting => translate('ideal_for_starting');
  String get forSmallBusinesses => translate('for_small_businesses');
  String get forProfessionals => translate('for_professionals');
  String get completeSolution => translate('complete_solution');

  // Common Actions - Duplicates removed, using earlier definitions
  String get add => translate('add');
  String get search => translate('search');
  String get filter => translate('filter');
  String get share => translate('share');
  String get download => translate('download');
  String get upload => translate('upload');
  String get confirm => translate('confirm');
  String get back => translate('back');
  String get next => translate('next');
  String get close => translate('close');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');

  // Messages
  String get success => translate('success');
  String get error => translate('error');
  String get warning => translate('warning');
  String get loading => translate('loading');
  String get noData => translate('no_data');
  String get requiredField => translate('required_field');
  String get passwordTooShort => translate('password_too_short');

  // Date & Time
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get tomorrow => translate('tomorrow');
  String get date => translate('date');
  String get time => translate('time');

  // Errors
  String get errorGeneric => translate('error_generic');
  String get errorNetwork => translate('error_network');
  String get errorAuth => translate('error_auth');
  String get errorPermission => translate('error_permission');

  // Profile Screen - Privacy & Data
  String get privacyAndData => translate('privacy_and_data');
  String get privacyPolicy => translate('privacy_policy');
  String get downloadMyData => translate('download_my_data');
  String get deleteMyAccount => translate('delete_my_account');
  String get signOut => translate('sign_out');
  String get resetLanguageDebug => translate('reset_language_debug');
  String get willShowInitialSelector => translate('will_show_initial_selector');
  String get languageResetMessage => translate('language_reset_message');

  // Profile Screen - Employee/Manager
  String get select => translate('select');
  String get change => translate('change');
  String get manager => translate('manager');
  String get nowWorkingAsManager => translate('now_working_as_manager');

  // Document Section
  String get saveInformation => translate('save_information');
  String get viewHistory => translate('view_history');
  String viewHistoryCount(int count) =>
      translate('view_history_count').replaceAll('{count}', count.toString());
  String get shareDocuments => translate('share_documents');
  String get whatsapp => translate('whatsapp');
  String get addPdf => translate('add_pdf');
  String get noPdfDocuments => translate('no_pdf_documents');
  String get selectDate => translate('select_date');
  String get selectFiles => translate('select_files');
  String get noDocumentsToShare => translate('no_documents_to_share');
  String get pleaseWriteNote => translate('please_write_note');
  String get noPhotos => translate('no_photos');
  String get openPdf => translate('open_pdf');
  String get downloadPdf => translate('download_pdf');
  String get expirationDateSaved => translate('expiration_date_saved');
  String get expirationDateSavedExpiredWarning =>
      translate('expiration_date_saved_expired_warning');
  String expirationBannerExpired(int days) => translate(
    'expiration_banner_expired',
  ).replaceAll('{days}', days.toString());
  String expirationBannerExpiringSoon(int days) => translate(
    'expiration_banner_expiring_soon',
  ).replaceAll('{days}', days.toString());
  String expirationBannerValid(int days) => translate(
    'expiration_banner_valid',
  ).replaceAll('{days}', days.toString());

  // Vehicle Inspection Checklist
  String get reset => translate('reset');
  String get resetChecklist => translate('reset_checklist');
  String get resetChecklistConfirmation =>
      translate('reset_checklist_confirmation');
  String get viewInspectionHistory => translate('view_inspection_history');
  String viewInspectionHistoryCount(int count) => translate(
    'view_inspection_history_count',
  ).replaceAll('{count}', count.toString());
  String get useSaveButton => translate('use_save_button');

  // Driver Section
  String get saveDriverInformation => translate('save_driver_information');
  String get driverInformationTitle => translate('driver_information_title');
  String get fullNameLabel => translate('full_name_label');
  String get phoneLabel => translate('phone_label');
  String get driverDocumentsTitle => translate('driver_documents_title');
  String get callTooltip => translate('call_tooltip');
  String get noPhoneSaved => translate('no_phone_saved');
  String get cannotMakeCall => translate('cannot_make_call');
  String errorCalling(String error) =>
      translate('error_calling').replaceAll('{error}', error);
  String driverInfoSavedHistory(int count) => translate(
    'driver_info_saved_history',
  ).replaceAll('{count}', count.toString());
  String get driverHistoryTitle => translate('driver_history_title');
  String get noHistoryRecords => translate('no_history_records');
  String get deleteRecordTitle => translate('delete_record_title');
  String get deleteRecordConfirmation =>
      translate('delete_record_confirmation');
  String get recordDeletedMessage => translate('record_deleted_message');
  String get driverRecordTitle => translate('driver_record_title');
  String driverRecordBannerTitle(String date) =>
      translate('driver_record_banner_title').replaceAll('{date}', date);
  String get notSpecified => translate('not_specified');
  String get noName => translate('no_name');
  String get noNotes => translate('no_notes');
  String get pdfSingular => translate('pdf_singular');
  String get pdfsPlural => translate('pdfs_plural');
  String pdfDocumentNumber(int number) => translate(
    'pdf_document_number',
  ).replaceAll('{number}', number.toString());
  String get downloadingPdf => translate('downloading_pdf');
  String pdfSavedIn(String path) =>
      translate('pdf_saved_in').replaceAll('{path}', path);
  String get errorOpeningPdf => translate('error_opening_pdf');
  String errorDownloadingWithError(String error) =>
      translate('error_downloading_with_error').replaceAll('{error}', error);
  String driverShareRecordText({
    required String date,
    required String name,
    required String phone,
    required String email,
    required String notes,
    required String photosCount,
    required String pdfsCount,
  }) {
    return translate('driver_share_record_text')
        .replaceAll('{date}', date)
        .replaceAll('{name}', name)
        .replaceAll('{phone}', phone)
        .replaceAll('{email}', email)
        .replaceAll('{notes}', notes)
        .replaceAll('{photos}', photosCount)
        .replaceAll('{pdfs}', pdfsCount);
  }

  // Maintenance Section
  String get saveRecord => translate('save_record');
  String get maintenanceRecordSingular =>
      translate('maintenance_record_singular');
  String get maintenanceRecordPlural => translate('maintenance_record_plural');
  String get maintSectionMotor => translate('maint_section_motor');
  String get maintSectionDireccion => translate('maint_section_direccion');
  String get maintSectionPintura => translate('maint_section_pintura');
  String get maintSectionRadiador => translate('maint_section_radiador');
  String get maintSectionSuspension => translate('maint_section_suspension');
  String get maintSectionAc => translate('maint_section_ac');
  String get maintSectionElectrico => translate('maint_section_electrico');
  String get maintSectionFrenos => translate('maint_section_frenos');
  String get maintSectionTransmision => translate('maint_section_transmision');
  String get maintenanceAddRecord => translate('maintenance_add_record');
  String get maintenanceDeleteRecordTitle =>
      translate('maintenance_delete_record_title');
  String get maintenanceDeleteRecordConfirmation =>
      translate('maintenance_delete_record_confirmation');
  String maintenanceDateKm(String date, String km) => translate(
    'maintenance_date_km',
  ).replaceAll('{date}', date).replaceAll('{km}', km);
  String get maintenanceAddRecordTitle =>
      translate('maintenance_add_record_title');
  String get maintenanceEditRecordTitle =>
      translate('maintenance_edit_record_title');
  String maintenanceSectionTitle(String sectionName) => translate(
    'maintenance_section_title',
  ).replaceAll('{sectionName}', sectionName);
  String get maintenanceProblemQuestion =>
      translate('maintenance_problem_question');
  String get maintenanceProblemHint => translate('maintenance_problem_hint');
  String get maintenanceRequiredField =>
      translate('maintenance_required_field');
  String get maintenancePhotosProblem =>
      translate('maintenance_photos_problem');
  String get maintenancePhotosOldParts =>
      translate('maintenance_photos_old_parts');
  String get maintenancePhotosNewParts =>
      translate('maintenance_photos_new_parts');
  String get maintenancePhotosAfter => translate('maintenance_photos_after');
  String get maintenanceCurrentKmLabel =>
      translate('maintenance_current_km_label');
  String get maintenanceNextChangeKmLabel =>
      translate('maintenance_next_change_km_label');
  String get maintenanceServiceDate => translate('maintenance_service_date');
  String get maintenanceSaveRecord => translate('maintenance_save_record');
  String maintenancePhotoUploadError(String error) =>
      translate('maintenance_photo_upload_error').replaceAll('{error}', error);
  String get maintenanceOdometerPhoto =>
      translate('maintenance_odometer_photo');
  String get maintenanceOdometerPhotoTap =>
      translate('maintenance_odometer_photo_tap');
  String maintenanceOdometerUploadError(String error) => translate(
    'maintenance_odometer_upload_error',
  ).replaceAll('{error}', error);

  // Delete Account Dialog
  String get deleteAccountWarning => translate('delete_account_warning');
  String get thisWillDelete => translate('this_will_delete');
  String get areYouSureContinue => translate('are_you_sure_continue');
  String get yourUserAccount => translate('your_user_account');
  String get allYourVehicles => translate('all_your_vehicles');
  String get allPhotosAndDocuments => translate('all_photos_and_documents');
  String get allMaintenanceHistory => translate('all_maintenance_history');
  String get confirmIdentity => translate('confirm_identity');
  String get forSecurityEnterPassword =>
      translate('for_security_enter_password');
  String get accountDeletedSuccessfully =>
      translate('account_deleted_successfully');

  // Data Export
  String get dataSharedSuccessfully => translate('data_shared_successfully');
  String errorExportingData(String error) =>
      translate('error_exporting_data').replaceAll('{error}', error);
  String errorSigningOut(String error) =>
      translate('error_signing_out').replaceAll('{error}', error);

  // Subscription Plans
  String get currentPlanLabel => translate('current_plan_label');
  String get selectPlan => translate('select_plan');

  // Additional Profile Screen UI Elements
  String get emailVerified => translate('email_verified');
  String get changePasswordTitle => translate('change_password_title');
  String get cancelButton => translate('cancel_button');
  String get changeButton => translate('change_button');
  String get emailLabel => translate('email_label');
  String get changeEmployeeLabel => translate('change_employee_label');
  String get currentLabel => translate('current_label');
  String get languageLabel => translate('language_label');
  String get manageEmployeesSubtitle => translate('manage_employees_subtitle');

  // Upgrade Banner
  String get upgradeYourPlan => translate('upgrade_your_plan');
  String get manageMoreVehiclesUnlimited =>
      translate('manage_more_vehicles_unlimited');
  String get youReachedYourLimit => translate('you_reached_your_limit');
  String get upgradePlanToAddMore => translate('upgrade_plan_to_add_more');

  // Maintenance Tabs
  String get inspectionChecklist => translate('inspection_checklist');
  String get detailedMaintenance => translate('detailed_maintenance');
  String get detailedMaintenanceDescription =>
      translate('detailed_maintenance_description');

  // Inspection Checklist - Items
  String get checkItemWindowsGlass => translate('check_item_windows_glass');
  String get checkItemMirrors => translate('check_item_mirrors');
  String get checkItemExteriorLights => translate('check_item_exterior_lights');
  String get checkItemBodyPaint => translate('check_item_body_paint');
  String get checkItemChassisFrame => translate('check_item_chassis_frame');
  String get checkItemDoorsLocks => translate('check_item_doors_locks');
  String get checkItemWindshield => translate('check_item_windshield');
  String get checkItemWipers => translate('check_item_wipers');
  String get checkItemHorn => translate('check_item_horn');
  String get checkItemSeatbelts => translate('check_item_seatbelts');
  String get checkItemUpholsterySeats =>
      translate('check_item_upholstery_seats');
  String get checkItemOdometer => translate('check_item_odometer');
  String get checkItemEngineOil => translate('check_item_engine_oil');
  String get checkItemOilFilter => translate('check_item_oil_filter');
  String get checkItemBrakeFluid => translate('check_item_brake_fluid');
  String get checkItemRadiatorFluid => translate('check_item_radiator_fluid');
  String get checkItemBelts => translate('check_item_belts');
  String get checkItemBattery => translate('check_item_battery');
  String get checkItemAirFilter => translate('check_item_air_filter');
  String get checkItemFuelFilter => translate('check_item_fuel_filter');
  String get checkItemSparkPlugsCables =>
      translate('check_item_spark_plugs_cables');
  String get checkItemHoses => translate('check_item_hoses');
  String get checkItemBatteryCharge => translate('check_item_battery_charge');
  String get checkItemBatteryCondition =>
      translate('check_item_battery_condition');
  String get checkItemFrontTirePressure =>
      translate('check_item_front_tire_pressure');
  String get checkItemRearTirePressure =>
      translate('check_item_rear_tire_pressure');
  String get checkItemFrontTireWear => translate('check_item_front_tire_wear');
  String get checkItemRearTireWear => translate('check_item_rear_tire_wear');
  String get checkItemTireBalancing => translate('check_item_tire_balancing');
  String get checkItemTireAlignment => translate('check_item_tire_alignment');
  String get checkItemTireRotation => translate('check_item_tire_rotation');

  // Getter aliases for backward compatibility
  String get checkItemChassis => checkItemChassisFrame;
  String get checkItemDoors => checkItemDoorsLocks;
  String get checkItemUpholstery => checkItemUpholsterySeats;
  String get checkItemCoolant => checkItemRadiatorFluid;
  String get checkItemSparkPlugs => checkItemSparkPlugsCables;
  String get checkItemWheelBalance => checkItemTireBalancing;
  String get checkItemWheelAlignment => checkItemTireAlignment;
  String get maxPhotosAllowed => max9PhotosAllowed;
  String get howToAddPhoto => howAddPhoto;
  String get confirmDeletePhoto => sureDeletePhoto;
  String get statusGood => checkedOk;
  String get statusImmediate => immediateAttention;
  String get maxPhotosPerComponent => max9PhotosPerComponent;
  String get noInspectionsSaved => noSavedInspections;
  String get useButtonToRecord => useSaveButtonToRecord;
  String get confirmDeleteInspection => sureDeleteInspection;

  // Inspection Checklist - Sections
  String get sectionInteriorExterior => translate('section_interior_exterior');
  String get sectionUnderHood => translate('section_under_hood');
  String get sectionTires => translate('section_tires');

  // Inspection Checklist - UI
  String get vehicleInspectionReport => translate('vehicle_inspection_report');
  String get clickBoxesToChangeStatus =>
      translate('click_boxes_to_change_status');
  String get tapButtonToAddPhotos => translate('tap_button_to_add_photos');
  String get swipeToSeeMorePhotos => translate('swipe_to_see_more_photos');
  String addPhotoCount(int count) =>
      translate('add_photo_count').replaceAll('{count}', count.toString());
  String get maxPhotosReached => translate('max_photos_reached');
  String get checkedOk => translate('checked_ok');
  String get requiresAttention => translate('requires_attention');
  String get immediateAttention => translate('immediate_attention');

  // Inspection Checklist - Dialogs
  String get addPhoto => translate('add_photo');
  String get howAddPhoto => translate('how_add_photo');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get deletePhoto => translate('delete_photo');
  String get sureDeletePhoto => translate('sure_delete_photo');

  // Inspection Checklist - Messages
  String get photoAddedNotSaved => translate('photo_added_not_saved');
  String get errorAddingPhoto => translate('error_adding_photo');
  String get photoDeleted => translate('photo_deleted');
  String get max9PhotosPerComponent => translate('max_9_photos_per_component');
  String photoAddedCount(int count) =>
      translate('photo_added_count').replaceAll('{count}', count.toString());
  String get photoNotFound => translate('photo_not_found');
  String get errorLoadingPhoto => translate('error_loading_photo');
  String get max9PhotosAllowed => translate('max_9_photos_allowed');
  String get savingInspection => translate('saving_inspection');
  String inspectionSavedHistory(int count) => translate(
    'inspection_saved_history',
  ).replaceAll('{count}', count.toString());
  String get errorSavingInspection => translate('error_saving_inspection');
  String get generatingPdf => translate('generating_pdf');
  String get errorGeneratingPdf => translate('error_generating_pdf');

  // Inspection History
  String get inspectionHistory => translate('inspection_history');
  String get noSavedInspections => translate('no_saved_inspections');
  String get useSaveButtonToRecord => translate('use_save_button_to_record');
  String get componentsChecked => translate('components_checked');
  String get delete => translate('delete');
  String get sharePdf => translate('share_pdf');
  String get deleteInspection => translate('delete_inspection');
  String get sureDeleteInspection => translate('sure_delete_inspection');
  String get inspectionDeleted => translate('inspection_deleted');
  String get savedInspection => translate('saved_inspection');
  String inspectionFromDate(String date) =>
      translate('inspection_from_date').replaceAll('{date}', date);
  String get readOnlyCannotModify => translate('read_only_cannot_modify');
  String get inspectionPhotos => translate('inspection_photos');
  String componentsReviewed(int count) =>
      translate('components_reviewed').replaceAll('{count}', count.toString());
  String get checklistResetPhotosCleared =>
      translate('checklist_reset_photos_cleared');
  String get downloadingPhoto => translate('downloading_photo');
  String get downloadingFiles => translate('downloading_files');
  String photoSavedIn(String path) =>
      translate('photo_saved_in').replaceAll('{path}', path);
  String get errorDownloading => translate('error_downloading');
  String get downloadReportZip => translate('download_report_zip');
  String get downloadingReport => translate('downloading_report');
  String get generatingZip => translate('generating_zip');
  String reportDownloaded(String path) =>
      translate('report_downloaded').replaceAll('{path}', path);
  String get errorDownloadingReport => translate('error_downloading_report');
  String get notesLabel => translate('notes_label');
  String get statusOk => translate('status_ok');
  String get statusAttention => translate('status_attention');
  String get statusUrgent => translate('status_urgent');
  String get photoSingular => translate('photo_singular');
  String get photosPlural => translate('photos_plural');

  // Expiration Alerts
  String get expirationAlerts => translate('expiration_alerts');

  // Document Types
  String get insurance => translate('insurance');
  String get circulationCard => translate('circulation_card');
  String get otherDocuments => translate('other_documents');
  String get ecologicalSticker => translate('ecological_sticker');

  // Warning Messages
  String insuranceExpiredDays(int days) =>
      translate('insurance_expired_days').replaceAll('{days}', days.toString());
  String insuranceExpiresInDays(int days) => translate(
    'insurance_expires_in_days',
  ).replaceAll('{days}', days.toString());
  String circulationCardExpiredDays(int days) => translate(
    'circulation_card_expired_days',
  ).replaceAll('{days}', days.toString());
  String circulationCardExpiresInDays(int days) => translate(
    'circulation_card_expires_in_days',
  ).replaceAll('{days}', days.toString());
  String otherDocumentsExpiredDays(int days) => translate(
    'other_documents_expired_days',
  ).replaceAll('{days}', days.toString());
  String otherDocumentsExpiresInDays(int days) => translate(
    'other_documents_expires_in_days',
  ).replaceAll('{days}', days.toString());
  String ecologicalStickerExpiredDays(int days) => translate(
    'ecological_sticker_expired_days',
  ).replaceAll('{days}', days.toString());
  String ecologicalStickerExpiresInDays(int days) => translate(
    'ecological_sticker_expires_in_days',
  ).replaceAll('{days}', days.toString());
  String get setExpirationDateNotification =>
      translate('set_expiration_date_notification');

  // Additional Document Section
  String get expirationDateLabel => translate('expiration_date_label');
  String get photos => translate('photos');
  String get pdfDocuments => translate('pdf_documents');
  String get notes => translate('notes');
  String get writeNotesAboutDocument => translate('write_notes_about_document');
  String get deletePhotoConfirmation => translate('delete_photo_confirmation');
  String get deleteDocumentConfirmation =>
      translate('delete_document_confirmation');
  String get deleteHistoryRecordConfirmation =>
      translate('delete_history_record_confirmation');
  String get deleteInspectionConfirmation =>
      translate('delete_inspection_confirmation');

  // Document Management Messages
  String documentNumber(int number) =>
      translate('document_number').replaceAll('{number}', number.toString());
  String get photoAddedSuccessfully => translate('photo_added_successfully');
  String errorUploadingPhoto(String error) =>
      translate('error_uploading_photo').replaceAll('{error}', error);
  String get photoDeletedSuccessfully =>
      translate('photo_deleted_successfully');
  String errorDeletingPhoto(String error) =>
      translate('error_deleting_photo').replaceAll('{error}', error);
  String get pdfAddedSuccessfully => translate('pdf_added_successfully');
  String errorUploadingPdf(String error) =>
      translate('error_uploading_pdf').replaceAll('{error}', error);
  String get pdfDeletedSuccessfully => translate('pdf_deleted_successfully');
  String errorDeletingPdf(String error) =>
      translate('error_deleting_pdf').replaceAll('{error}', error);
  String get pleaseWriteNoteBeforeSaving =>
      translate('please_write_note_before_saving');
  String get notesSavedAndAddedToHistory =>
      translate('notes_saved_and_added_to_history');
  String get preparingFilesToShare => translate('preparing_files_to_share');
  String get sharingViaWhatsapp => translate('sharing_via_whatsapp');
  String get sharingViaEmail => translate('sharing_via_email');
  String errorSharing(String error) =>
      translate('error_sharing').replaceAll('{error}', error);
  String get noDocumentsOrPhotosToShare =>
      translate('no_documents_or_photos_to_share');
  String get all => translate('all');
  String get selectAtLeastOneFile => translate('select_at_least_one_file');
  String get shareMessageVehicleLabel =>
      translate('share_message_vehicle_label');
  String get shareMessageExpiresLabel =>
      translate('share_message_expires_label');
  String get shareMessageStatusExpired =>
      translate('share_message_status_expired');
  String shareMessageStatusExpiring(int days) => translate(
    'share_message_status_expiring',
  ).replaceAll('{days}', days.toString());
  String get shareMessageStatusValid => translate('share_message_status_valid');
  String get shareMessageNotesLabel => translate('share_message_notes_label');
  String shareEmailSubject(String title, String vehicleId) => translate(
    'share_email_subject',
  ).replaceAll('{title}', title).replaceAll('{vehicleId}', vehicleId);
  String shareEmailBodyIntro(String title) =>
      translate('share_email_body_intro').replaceAll('{title}', title);
  String shareEmailVehicleId(String vehicleId) =>
      translate('share_email_vehicle_id').replaceAll('{vehicleId}', vehicleId);
  String shareEmailExpirationDate(String date) =>
      translate('share_email_expiration_date').replaceAll('{date}', date);
  String get shareEmailStatusExpired => translate('share_email_status_expired');
  String shareEmailStatusExpiring(int days) => translate(
    'share_email_status_expiring',
  ).replaceAll('{days}', days.toString());
  String get shareEmailStatusValid => translate('share_email_status_valid');
  String get shareEmailNotesHeader => translate('share_email_notes_header');
  String historyTitle(String title) =>
      translate('history_title').replaceAll('{title}', title);
  String get historyEmptyTitle => translate('history_empty_title');
  String get historyEmptySubtitle => translate('history_empty_subtitle');
  String get historySavedDateLabel => translate('history_saved_date_label');
  String get historyExpirationDateLabel =>
      translate('history_expiration_date_label');
  String get historyPhotosLabel => translate('history_photos_label');
  String get historyPdfsLabel => translate('history_pdfs_label');
  String get historyNotesLabel => translate('history_notes_label');
  String historyShareSubject(String title, String date) => translate(
    'history_share_subject',
  ).replaceAll('{title}', title).replaceAll('{date}', date);
  String get employeeViewTitle => translate('employee_view_title');
  String get readOnlyViewTitle => translate('read_only_view_title');
  String recordSavedOn(String title, String date) => translate(
    'record_saved_on',
  ).replaceAll('{title}', title).replaceAll('{date}', date);
  String get documentInformationTitle =>
      translate('document_information_title');
  String get documentLabel => translate('document_label');
  String photosSectionTitle(int count) =>
      translate('photos_section_title').replaceAll('{count}', count.toString());
  String pdfsSectionTitle(int count) =>
      translate('pdfs_section_title').replaceAll('{count}', count.toString());
  String get withNotesLabel => translate('with_notes_label');
  String photoNumber(int number) =>
      translate('photo_number').replaceAll('{number}', number.toString());
  String expiresLabel(String date) =>
      translate('expires_label').replaceAll('{date}', date);

  // Storage and Records
  String get storagePermissionDenied => translate('storage_permission_denied');
  String get recordDeleted => translate('record_deleted');
  String get recordSaved => translate('record_saved');

  // Export Reports
  String get exportReports => translate('export_reports');
  String get exportReportsPDF => translate('export_reports_pdf');
  String get generateVehicleReports => translate('generate_vehicle_reports');
  String get selectAtLeastOneVehicle =>
      translate('select_at_least_one_vehicle');
  String get selectAtLeastOneReportType =>
      translate('select_at_least_one_report_type');
  String get errorGeneratingReport => translate('error_generating_report');
  String get noVehiclesRegistered => translate('no_vehicles_registered');
  String get addVehiclesToGenerateReports =>
      translate('add_vehicles_to_generate_reports');
  String get generateConsolidatedPDFReport =>
      translate('generate_consolidated_pdf_report');
  String get selectVehicles => translate('select_vehicles');
  String get dateRange => translate('date_range');
  String get reportTypes => translate('report_types');
  String get allVehicles => translate('all_vehicles');
  String get vehiclesAvailable => translate('vehicles_available');
  String get from => translate('from');
  String get to => translate('to');
  String get maintenances => translate('maintenances');
  String get maintenanceHistory => translate('maintenance_history');
  String get inspections => translate('inspections');
  String get checklistReports => translate('checklist_reports');
  String get insuranceDriverCirculation =>
      translate('insurance_driver_circulation');
  String get reportWillBeGenerated => translate('report_will_be_generated');
  String get vehicleSingular => translate('vehicle_singular');
  String get vehiclesPlural => translate('vehicles_plural');
  String get reportTypeSingular => translate('report_type_singular');
  String get reportTypesPlural => translate('report_types_plural');
  String get exportReportsButton => translate('export_reports_button');
  String get generatingReport => translate('generating_report');
  String get fleetReportAutogestionMax =>
      translate('fleet_report_autogestion_max');
  String get pleaseWait => translate('please_wait');

  // Subscriptions
  String get couldNotLoadSubscriptions =>
      translate('could_not_load_subscriptions');
  String get verificationComplete => translate('verification_complete');
  String get enterprisePlan => translate('enterprise_plan');
  String get manageSubscription => translate('manage_subscription');
  String get understood => translate('understood');
  String get contact => translate('contact');

  // Inspection
  String get inspectionSaved => translate('inspection_saved');

  // Debug
  String get debugInfo => translate('debug_info');
  String get reloadData => translate('reload_data');
  String get uidCopiedClipboard => translate('uid_copied_clipboard');
  String get copyUid => translate('copy_uid');

  // General texts
  String get retry => translate('retry');
  String get openSettings => translate('open_settings');

  // Error messages
  String get userNotAuthenticated => translate('user_not_authenticated');
  String get currentPasswordIncorrect =>
      translate('current_password_incorrect');
  String get errorChangingPassword => translate('error_changing_password');
  String get couldNotCreateZip => translate('could_not_create_zip');
  String get requiresRecentLoginMessage =>
      translate('requires_recent_login_message');
  String get biometricUserMismatch => translate('biometric_user_mismatch');
  String get errorInitializingApp => translate('error_initializing_app');
  String get errorVerifyingAuth => translate('error_verifying_auth');
  String get pleaseRestartApp => translate('please_restart_app');
  String errorMessage(String message) =>
      translate('error_message').replaceAll('{message}', message);

  // Billing Screen
  String get billingAndExpenses => translate('billing_and_expenses');
  String get billingDescription => translate('billing_description');
  String get filters => translate('filters');
  String get categoryLabel => translate('category_label');
  String get allCategories => translate('all_categories');
  String get categoriesLabel => translate('categories_label');
  String get noMatches => translate('no_matches');
  String get done => translate('done');
  String get exportPdf => translate('export_pdf');
  String get exportExcel => translate('export_excel');
  String totalPeriod(String period) =>
      translate('total_period').replaceAll('{period}', period);
  String expensesRegisteredN(int n) =>
      translate('expenses_registered_n').replaceAll('{n}', n.toString());
  String get activeVehicles => translate('active_vehicles');
  String get withExpensesRegistered => translate('with_expenses_registered');
  String get expenseTypes => translate('expense_types');
  String get expensesByVehicle => translate('expenses_by_vehicle');
  String get distributionByCategory => translate('distribution_by_category');
  String get noExpensesInPeriod => translate('no_expenses_in_period');
  String get recentExpenses => translate('recent_expenses');
  String get noExpenses => translate('no_expenses');
  String get noExpensesWithFilters => translate('no_expenses_with_filters');
  String get registerExpense => translate('register_expense');
  String get registerExpenseSubtitle => translate('register_expense_subtitle');
  String get noVehiclesAvailable => translate('no_vehicles_available');
  String get selectAVehicle => translate('select_a_vehicle');
  String get vehicleRequired => translate('vehicle_required');
  String get categoryRequired => translate('category_required');
  String get amountMxnRequired => translate('amount_mxn_required');
  String get dateRequired => translate('date_required');
  String get mileageOptional => translate('mileage_optional');
  String get receiptOptional => translate('receipt_optional');
  String get odometerPhotoLabel => translate('odometer_photo_label');
  String get attachedLabel => translate('attached_label');
  String get scanQr => translate('scan_qr');
  String get qrScanned => translate('qr_scanned');
  String get receiptPhotoLabel => translate('receipt_photo_label');
  String get receiptPdfLabel => translate('receipt_pdf_label');
  String get enterValidAmount => translate('enter_valid_amount');
  String get expenseAddedSuccessfully =>
      translate('expense_added_successfully');
  String errorSavingExpense(String error) =>
      translate('error_saving_expense').replaceAll('{error}', error);
  String get qrSatDetected => translate('qr_sat_detected');
  String get qrCustomDetected => translate('qr_custom_detected');
  String get qrSavedAsText => translate('qr_saved_as_text');
  String get cameraPermissionQr => translate('camera_permission_qr');
  String errorSelectingPdfFile(String error) =>
      translate('error_selecting_pdf_file').replaceAll('{error}', error);
  String errorCapturingPhotoExpense(String error) =>
      translate('error_capturing_photo_expense').replaceAll('{error}', error);
  String get expenseDetails => translate('expense_details');
  String get amountLabel => translate('amount_label');
  String get descriptionLabel => translate('description_label');
  String get confirmDeleteExpenseTitle =>
      translate('confirm_delete_expense_title');
  String get confirmDeleteExpense => translate('confirm_delete_expense');
  String get expenseDeletedSuccessfully =>
      translate('expense_deleted_successfully');
  String get viewPeriod => translate('view_period');
  String get apply => translate('apply');
  String get yearTab => translate('year_tab');
  String get monthTab => translate('month_tab');
  String get weekTab => translate('week_tab');
  String get dayTab => translate('day_tab');
  List<String> get weekdayAbbr => [
    translate('weekday_mon'),
    translate('weekday_tue'),
    translate('weekday_wed'),
    translate('weekday_thu'),
    translate('weekday_fri'),
    translate('weekday_sat'),
    translate('weekday_sun'),
  ];
  String get exportExcelCsv => translate('export_excel_csv');
  String get vehiclesToInclude => translate('vehicles_to_include');
  String get generatingPdfProgress => translate('generating_pdf_progress');
  String get generatingCsvProgress => translate('generating_csv_progress');
  String get expensesReportTitle => translate('expenses_report_title');
  String get periodLabel => translate('period_label');
  String generatedOn(String date) =>
      translate('generated_on').replaceAll('{date}', date);
  String get noExpensesForPeriod => translate('no_expenses_for_period');
  String get totalMxnLabel => translate('total_mxn_label');
  String get receiptsLabel => translate('receipts_label');
  String errorGeneratingPdfExport(String error) =>
      translate('error_generating_pdf_export').replaceAll('{error}', error);
  String errorGeneratingCsvExport(String error) =>
      translate('error_generating_csv_export').replaceAll('{error}', error);
  String get pdfColVehicle => translate('pdf_col_vehicle');
  String get pdfColCategory => translate('pdf_col_category');
  String get pdfColDescription => translate('pdf_col_description');
  String get pdfColDate => translate('pdf_col_date');
  String get pdfColAmount => translate('pdf_col_amount');
  String get expenseCatFuel => translate('expense_cat_fuel');
  String get expenseCatMaintenance => translate('expense_cat_maintenance');
  String get expenseCatInsurance => translate('expense_cat_insurance');
  String get expenseCatToll => translate('expense_cat_toll');
  String get expenseCatParking => translate('expense_cat_parking');
  String get expenseCatRepair => translate('expense_cat_repair');
  String get expenseCatOther => translate('expense_cat_other');
  String get scanQrTitle => translate('scan_qr_title');
  String get cameraPermissionNotGranted =>
      translate('camera_permission_not_granted');
  String get qrPositionInFrame => translate('qr_position_in_frame');
  String get searchNamePlateBrand => translate('search_name_plate_brand');
  String get searchNamePlate => translate('search_name_plate');
  String get expensesLabel => translate('expenses_label');
  String get notesOptional => translate('notes_optional');
  String get mileageHint => translate('mileage_hint');
  String get notesHint => translate('notes_hint');
  String get photoButtonLabel => translate('photo_button_label');

  // Employee management
  String get noEmployeesRegistered => translate('no_employees_registered');
  String get pressAddButton => translate('press_add_button');
  String get hasBeenDeactivated => translate('has_been_deactivated');
  String get hasBeenActivated => translate('has_been_activated');
  String get hasBeenDeleted => translate('has_been_deleted');
  String get deleteEmployeeTitle => translate('delete_employee_title');
  String get deleteIrreversibleAction =>
      translate('delete_irreversible_action');
  String get deactivatedLabel => translate('deactivated_label');
  String get deleteEmployeeTooltip => translate('delete_employee_tooltip');
  String get fullNameHint => translate('full_name_hint');

  // Export save to device
  String get saveToDevice => translate('save_to_device');
  String fileSavedSuccess(String path) =>
      translate('file_saved_success').replaceAll('{path}', path);
  String get openFile => translate('open_file');
  String errorSavingFile(String error) =>
      translate('error_saving_file').replaceAll('{error}', error);

  // PDF/CSV export receipt labels
  String get pdfReceiptsTitle => translate('pdf_receipts_title');
  String get pdfReceiptsSubtitle => translate('pdf_receipts_subtitle');
  String get qrReceiptsTitle => translate('qr_receipts_title');
  String get qrReceiptsSubtitle => translate('qr_receipts_subtitle');
  String get viewReceiptLink => translate('view_receipt_link');
  String get receiptColHeader => translate('receipt_col_header');
  String get downloadReceiptLink => translate('download_receipt_link');

  // Profile name editing
  String get changeName => translate('change_name');
  String get newName => translate('new_name');
  String get nameUpdated => translate('name_updated');
  String get errorUpdatingName => translate('error_updating_name');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'es',
      'en',
      'pt',
      'fr',
      'de',
      'it',
      'zh',
      'ja',
      'ar',
      'ru',
      'hi',
      'ko',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
