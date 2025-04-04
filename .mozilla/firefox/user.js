// Don't download pdfs by default
defaultPref("browser.download.open_pdf_attachments_inline", true)

// Force dark theme
defaultPref("systemUsesDarkTheme", true)

// Allow custom theming
defaultPref("toolkit.legacyUserProfileCustomizations.stylesheets", true)

// Disable config warning
defaultPref("browser.aboutConfig.showWarning", false)

// Disable default bookmarks
defaultPref("browser.bookmarks.restore_default_bookmarks", false)

// Disable full screen popup
defaultPref("full-screen-api.transition.timeout", 0)
defaultPref("full-screen-api.warning.delay", 0)
defaultPref("full-screen-api.warning.timeout", 0)

// Fixes some issues
defaultPref("security.tls.enable_0rtt_data", false)

//Disable stupid scroll bounce 
defaultPref("apz.overscroll.enabled", false)

// Disable ctrl+q
defaultPref("browser.quitShortcut.disabled", true)

// Disable pocket
defaultPref("extensions.pocket.enabled", false)

