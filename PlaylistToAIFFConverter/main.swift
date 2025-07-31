import SwiftUI
import PlaylistParser
import AudioConverter
import FileLocator

@main
struct PlaylistToAIFFConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ConversionViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HeaderView()
                
                PlaylistImportView(viewModel: viewModel)
                
                if viewModel.hasPlaylist {
                    FileDiscoveryView(viewModel: viewModel)
                    
                    ConversionSettingsView(viewModel: viewModel)
                    
                    ConversionProgressView(viewModel: viewModel)
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 800, minHeight: 600)
        }
    }
}

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("iTunes Playlist to AIFF Converter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Convert your iTunes playlists to AIFF format for Traktor Pro 4")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom)
    }
}

struct PlaylistImportView: View {
    @ObservedObject var viewModel: ConversionViewModel
    @State private var isTargeted = false
    
    var body: some View {
        VStack {
            Text("Import Playlist")
                .font(.headline)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .stroke(isTargeted ? Color.blue : Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(isTargeted ? .blue : .gray)
                        
                        Text("Drop playlist file here or click to browse")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Supports: XML, M3U, M3U8, TXT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                }
                .onTapGesture {
                    showFilePicker()
                }
            
            if let playlist = viewModel.playlist {
                HStack {
                    Text("Loaded: \(playlist.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(playlist.tracks.count) tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                viewModel.loadPlaylist(from: url)
            }
        }
        
        return true
    }
    
    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.loadPlaylist(from: url)
        }
    }
}

struct FileDiscoveryView: View {
    @ObservedObject var viewModel: ConversionViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("File Discovery")
                    .font(.headline)
                
                Spacer()
                
                Button("Locate Files") {
                    viewModel.locateFiles()
                }
                .disabled(viewModel.isLocatingFiles)
            }
            
            if viewModel.isLocatingFiles {
                ProgressView("Locating files...")
                    .frame(maxWidth: .infinity)
            } else if !viewModel.fileResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewModel.fileResults.enumerated()), id: \.offset) { index, result in
                            FileResultRow(result: result, index: index)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .border(Color.gray.opacity(0.3))
            }
        }
    }
}

struct FileResultRow: View {
    let result: FileLocationResult
    let index: Int
    
    var body: some View {
        HStack {
            Image(systemName: result.isFound ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(result.isFound ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(URL(fileURLWithPath: result.originalPath).lastPathComponent)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let resolvedPath = result.resolvedPath {
                    Text(resolvedPath)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("File not found")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Text(result.method.description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct ConversionSettingsView: View {
    @ObservedObject var viewModel: ConversionViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Conversion Settings")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Output Format")
                        .font(.subheadline)
                    
                    Picker("Format", selection: $viewModel.outputFormat) {
                        Text("AIFF (Recommended for Traktor)").tag(AudioFormat.aiff)
                        Text("WAV").tag(AudioFormat.wav)
                    }
                    .pickerStyle(.menu)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Quality")
                        .font(.subheadline)
                    
                    Picker("Quality", selection: $viewModel.quality) {
                        Text("High (Recommended)").tag(ConversionQuality.high)
                        Text("Maximum").tag(ConversionQuality.maximum)
                        Text("Medium").tag(ConversionQuality.medium)
                        Text("Low").tag(ConversionQuality.low)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            HStack {
                Text("Output Directory:")
                    .font(.subheadline)
                
                Text(viewModel.outputDirectory)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Button("Choose...") {
                    viewModel.selectOutputDirectory()
                }
            }
        }
    }
}

struct ConversionProgressView: View {
    @ObservedObject var viewModel: ConversionViewModel
    
    var body: some View {
        VStack {
            HStack {
                Button(viewModel.isConverting ? "Cancel" : "Start Conversion") {
                    if viewModel.isConverting {
                        viewModel.cancelConversion()
                    } else {
                        viewModel.startConversion()
                    }
                }
                .disabled(!viewModel.canStartConversion)
                
                Spacer()
                
                if viewModel.isConverting {
                    Text("\(viewModel.completedConversions)/\(viewModel.totalConversions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.isConverting {
                ProgressView(value: viewModel.conversionProgress)
                    .progressViewStyle(.linear)
                
                Text(viewModel.currentConversionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !viewModel.conversionResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewModel.conversionResults.enumerated()), id: \.offset) { index, result in
                            ConversionResultRow(result: result)
                        }
                    }
                }
                .frame(maxHeight: 150)
                .border(Color.gray.opacity(0.3))
            }
        }
    }
}

struct ConversionResultRow: View {
    let result: AudioConversionResult
    
    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(URL(fileURLWithPath: result.inputPath).lastPathComponent)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let error = result.error {
                    Text(error.localizedDescription)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                } else if let outputPath = result.outputPath {
                    Text("→ \(URL(fileURLWithPath: outputPath).lastPathComponent)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if result.success {
                Text(String(format: "%.1fs", result.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

