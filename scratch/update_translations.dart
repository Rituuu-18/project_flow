import 'dart:io';

void main() {
  final file = File('lib/core/localization/translations.dart');
  final content = file.readAsStringSync();

  final germanMap = """  'de': {
    // Auth - Login
    'login_title': 'Willkommen zurück',
    'login_subtitle': 'Bitte geben Sie Ihre Daten ein, um sich anzumelden.',
    'email_label': 'E-Mail-Adresse',
    'password_label': 'Passwort',
    'sign_in_button': 'Anmelden',
    'no_account': 'Sie haben noch kein Konto? ',
    'sign_up': 'Registrieren',
    'forgot_password': 'Passwort vergessen?',
    'sign_in_action': 'Anmelden',
    'no_account_text': 'Sie haben noch kein Konto?',
    'register_here': 'Hier registrieren',
    'enter_valid_email': 'Geben Sie eine gültige E-Mail-Adresse ein',
    'enter_password': 'Geben Sie Ihr Passwort ein',
    'enter_valid_email_password_to_continue':
        'Geben Sie eine gültige E-Mail-Adresse und ein Passwort ein, um fortzufahren.',
    'signed_in_successfully': 'Erfolgreich angemeldet.',
    'please_sign_in_to_open':
        'Bitte melden Sie sich an, um das Dashboard zu öffnen und Reviews zu speichern.',

    // Auth - Register
    'create_account_title': 'Konto erstellen',
    'create_account_subtitle':
        'Treten Sie Evalio Design bei, um an Engineering-Reviews zusammenzuarbeiten.',
    'first_name': 'Vorname',
    'last_name': 'Nachname',
    'confirm_password': 'Passwort bestätigen',
    'passwords_mismatch': 'Passwörter stimmen nicht überein',
    'required_field': 'Erforderlich',
    'please_enter_email': 'Bitte geben Sie Ihre E-Mail ein',
    'please_enter_valid_email': 'Bitte geben Sie eine gültige E-Mail-Adresse ein',
    'please_enter_password': 'Bitte geben Sie ein Passwort ein',
    'password_min_length': 'Das Passwort muss mindestens 8 Zeichen lang sein',
    'account_created_signed_in': 'Konto erstellt. Sie sind angemeldet.',
    'account_created_sign_in':
        'Konto erstellt. Melden Sie sich mit Ihrer E-Mail und Ihrem Passwort an.',
    'already_have_account': 'Haben Sie bereits ein Konto?',
    'sign_in_here': 'Hier anmelden',
    'please_complete_all_fields':
        'Bitte füllen Sie alle erforderlichen Felder korrekt aus.',
    'registration_failed': 'Registrierung fehlgeschlagen.',

    // Auth - Forgot Password
    'reset_password_title': 'Passwort zurücksetzen',
    'reset_password_subtitle':
        'Geben Sie Ihre E-Mail-Adresse ein und wir senden Ihnen einen Link, um Ihr Passwort zurückzusetzen.',
    'send_reset_link': 'Reset-Link senden',
    'check_inbox_title': 'Überprüfen Sie Ihren Posteingang',
    'check_inbox_message': 'Wir haben einen Link zum Zurücksetzen des Passworts an\\n{email} gesendet.',
    'back_to_sign_in': 'Zurück zur Anmeldung',
    'enter_valid_email_reset': 'Geben Sie eine gültige E-Mail ein, um Ihr Passwort zurückzusetzen.',
    'reset_link_sent': 'Wenn diese E-Mail existiert, wurde ein Reset-Link gesendet.',
    'could_not_send_reset_email': 'Reset-E-Mail konnte nicht gesendet werden.',

    // Dashboard
    'dashboard_hero':
        'Schritt-für-Schritt-Design-Anleitung, die sicherstellt, dass kritische Anforderungen, Risiken und Entscheidungen nicht übersehen werden – und teure Nacharbeiten sowie Probleme im Produktlebenszyklus verhindert.',
    'new_design_review': 'Neues Design-Review',
    'search_reviews': 'Reviews durchsuchen...',
    'active': 'Aktiv',
    'completed': 'Abgeschlossen',
    'active_reviews_title': 'Aktive Design-Reviews',
    'active_reviews_subtitle': 'In Bearbeitung und ausstehende Überprüfung',
    'completed_reviews_title': 'Abgeschlossene Reviews',
    'completed_reviews_subtitle': 'Vergangene Entscheidungen und Aufzeichnungen',

    // New Review Dialog
    'create_design_review_label': 'DESIGN-REVIEW ERSTELLEN',
    'new_design_review_dialog_title': 'Neues Design-Review',
    'new_design_review_description':
        'Fügen Sie den Namen des Reviews, den Eigentümer und die Disziplin hinzu. Sie können später Nachweise anhängen und Entscheidungen erfassen.',
    'design_review_name': 'NAME DES DESIGN-REVIEWS',
    'gearbox_hint': 'z.B. Getriebedeckel Rev A',
    'owner_label': 'EIGENTÜMER',
    'discipline_label': 'DISZIPLIN',
    'owner_hint': 'Eigentümer',
    'discipline_hint_caps': 'Disziplin',
    'cancel': 'Abbrechen',
    'create': 'Erstellen',

    // Dashboard States
    'no_matching_reviews': 'Keine passenden Reviews',
    'no_reviews_yet': 'Noch keine Design-Reviews.',
    'search_hint': 'Suchen Sie nach Projektname, Eigentümer, Disziplin oder Status.',
    'click_button_above': 'Klicken Sie auf den obigen Button, um eines zu starten.',
    'create_review': 'Review erstellen',
    'reviews_load_error': 'Reviews konnten nicht geladen werden',
    'try_again': 'Erneut versuchen',

    // Premium Review Card
    'progress_label': 'Fortschritt',
    'in_progress': 'In Bearbeitung',
    'review_pending': 'Überprüfung ausstehend',
    'completed_status': 'Abgeschlossen',
    'upload_image': 'Bild hochladen',
    'prepare_slide': 'Folie vorbereiten',
    'make_copy': 'Kopie erstellen',
    'create_pdf': 'PDF erstellen',
    'delete': 'Löschen',
    'preview_unavailable': 'Vorschau nicht verfügbar',
    'add_preview_image': 'Vorschaubild hinzufügen',
    'no_owner_discipline': 'Kein Eigentümer oder Disziplin hinzugefügt',
    'owner_prefix': 'Eigentümer: {owner}',

    // Review Detail
    'back_to_dashboard': 'Zurück zum Dashboard',
    'steps_count': '{count} Schritte',
    'design_review_steps': 'Design-Review-Schritte',
    'stakeholders': 'STAKEHOLDER',
    'stakeholder_name': 'Name des Stakeholders',
    'role_or_discipline': 'Rolle oder Disziplin',
    'add_stakeholder': 'Stakeholder hinzufügen',
    'no_checklist': 'Keine Checkliste',
    'export_pdf': 'PDF exportieren',
    'delete_review': 'Review löschen',
    'no_stages': 'Keine Phasen verfügbar.',
    'stage_complete': 'abgeschlossen',
    'design_review_workflow': 'Design-Review-Workflow',
    'design_review_not_found': 'Design-Review nicht gefunden',
    'go_back': 'Zurückgehen',
    'open_workspace': 'Arbeitsbereich öffnen',
    'substep_header': 'TEILSCHRITT',
    'status_header': 'STATUS',
    'action_header': 'AKTION',
    'status_open': 'Offen',
    'status_completed': 'Abgeschlossen',
    'status_not_required': 'Nicht erforderlich',
    'all_not_required': 'Alle nicht erforderlich',
    'stage_complete_progress': '{completed}/{applicable} abgeschlossen',
    'enter_stakeholder_name': 'Geben Sie zuerst einen Stakeholder-Namen ein.',
    'stakeholder_added': 'Stakeholder hinzugefügt.',
    'save_checklist_error': 'Checklisten-Änderung konnte nicht gespeichert werden.',
    'delete_review_dialog_title': 'Design-Review löschen?',
    'delete_review_dialog_message':
        '"{name}" und die gespeicherten Review-Daten werden dauerhaft entfernt.',
    'cancel_button': 'Abbrechen',
    'delete_button': 'Löschen',

    // Workspace
    'back_to_review': 'Zurück zur Review-Seite',
    'item_details': 'Elementdetails',
    'managed_by_admin': 'Von einem Admin verwaltet',
    'checklist_item': 'Checklisten-Element',
    'description_label': 'Beschreibung',
    'add_details': 'Details hinzufügen',
    'notes': 'Notizen',
    'enter_notes': 'Notizen eingeben...',
    'evidence_actions': 'Nachweise & Aktionen',
    'file_upload': 'Datei-Upload',
    'drop_files_here': 'Bilder, PDFs, CAD-Dateien, Zeichnungen hier ablegen',
    'browse_files': 'Dateien durchsuchen',
    'action_required': 'Aktion erforderlich',
    'action_description': 'Aktionsbeschreibung',
    'describe_action': 'Aktion beschreiben...',
    'assignment': 'Zuweisung',
    'responsible_person': 'Verantwortliche Person (Stakeholder)',
    'select_stakeholder': 'Stakeholder auswählen...',
    'discipline': 'Disziplin',
    'due_date': 'Fälligkeitsdatum',
    'select_date': 'Datum auswählen',
    'clear': 'Löschen',
    'activity': 'Aktivität',
    'no_recent_activity': 'Keine kürzliche Aktivität.',
    'save_progress': 'Fortschritt speichern',
    'loading_workspace': 'Lade Arbeitsbereich...',
    'not_provided': 'Nicht angegeben',
    'retry': 'Wiederholen',
    'assigned_to_name': 'Zugewiesen an {name}',
    'assigned_to_name_role': 'Zugewiesen an {name} ({role})',
    'changed_due_date': 'Fälligkeitsdatum auf {date} geändert',
    'cleared_due_date': 'Fälligkeitsdatum gelöscht',
    'no_stakeholders_yet_empty':
        'Noch keine Stakeholder. Fügen Sie sie auf der Design-Review-Seite hinzu — sie erscheinen dann hier, und die Disziplin wird aus ihrer Rolle ausgefüllt.',
    'no_stakeholders_yet_current':
        'Noch keine Stakeholder. Aktueller Bearbeiter: {assignee}. Fügen Sie Stakeholder auf der Design-Review-Seite hinzu, um sie aus der Liste auszuwählen.',
    'could_not_load_stakeholders_empty': 'Stakeholder konnten nicht geladen werden.',
    'could_not_load_stakeholders_current':
        'Stakeholder konnten nicht geladen werden. Aktueller Bearbeiter: {assignee}',
    'loading_stakeholders_empty': 'Lade Stakeholder…',
    'loading_stakeholders_current': 'Lade Stakeholder… Aktuell: {assignee}',
    'auto_filled_role': 'Automatisch aus Stakeholder-Rolle ausgefüllt',
    'discipline_hint': 'Disziplin...',
  },""";

  final regex = RegExp(r"  'de': \{.*?\n  \},", dotAll: true);
  if (regex.hasMatch(content)) {
    final newContent = content.replaceFirst(regex, germanMap);
    file.writeAsStringSync(newContent);
    print("Replaced 'de' map with actual German translations.");
  } else {
    print("Could not find 'de' block in the file.");
  }
}
