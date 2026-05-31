import AppKit
import SwiftUI

struct AboutSettingsTab: View {
  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 40)

      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: 128, height: 128)

      Spacer().frame(height: 8)

      Text(AppMetadata.name)
        .font(.largeTitle)
        .fontWeight(.bold)

      Text(SettingsStrings.aboutSlogan)
        .font(.title3)
        .padding(.top, 6)

      Text(SettingsStrings.aboutVersion(AppMetadata.version))
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.top, 6)

      Spacer().frame(height: 40)

      Button {
        NSApp.terminate(nil)
      } label: {
        Text(SettingsStrings.advancedQuitApp)
          .foregroundStyle(Color(.systemRed))
          .padding(.horizontal, 16)
          .padding(.vertical, 4)
      }

      Spacer(minLength: 24)

      Text(SettingsStrings.aboutCopyright)
        .font(.callout)
        .foregroundStyle(.secondary)

      Spacer().frame(height: 48)
    }
    .frame(maxWidth: .infinity)
  }
}
