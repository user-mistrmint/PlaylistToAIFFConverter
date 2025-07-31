import XCTest
@testable import PlaylistParser

final class PlaylistParserTests: XCTestCase {
    var parser: PlaylistParser!
    
    override func setUp() {
        super.setUp()
        parser = PlaylistParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    func testSupportedExtensions() {
        let extensions = parser.supportedExtensions
        XCTAssertTrue(extensions.contains("xml"))
        XCTAssertTrue(extensions.contains("m3u"))
        XCTAssertTrue(extensions.contains("m3u8"))
        XCTAssertTrue(extensions.contains("txt"))
    }
    
    func testTrackCreation() {
        let track = Track(
            id: "123",
            name: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            originalPath: "/path/to/song.mp3"
        )
        
        XCTAssertEqual(track.id, "123")
        XCTAssertEqual(track.name, "Test Song")
        XCTAssertEqual(track.artist, "Test Artist")
        XCTAssertEqual(track.album, "Test Album")
        XCTAssertEqual(track.duration, 180.0)
        XCTAssertEqual(track.originalPath, "/path/to/song.mp3")
    }
    
    func testPlaylistCreation() {
        let tracks = [
            Track(id: "1", name: "Song 1", artist: "Artist 1", album: "Album 1", duration: 180.0, originalPath: "/path/1.mp3"),
            Track(id: "2", name: "Song 2", artist: "Artist 2", album: "Album 2", duration: 200.0, originalPath: "/path/2.mp3")
        ]
        
        let playlist = Playlist(name: "Test Playlist", tracks: tracks)
        
        XCTAssertEqual(playlist.name, "Test Playlist")
        XCTAssertEqual(playlist.tracks.count, 2)
        XCTAssertEqual(playlist.totalDuration, 380.0)
    }
    
    func testPlaylistFormatDescription() {
        XCTAssertEqual(PlaylistFormat.xml.description, "iTunes XML Playlist")
        XCTAssertEqual(PlaylistFormat.m3u.description, "M3U Playlist")
        XCTAssertEqual(PlaylistFormat.m3u8.description, "M3U8 Extended Playlist")
        XCTAssertEqual(PlaylistFormat.txt.description, "Text Playlist")
    }
    
    func testParseOptionsDefault() {
        let options = PlaylistParseOptions.default
        XCTAssertEqual(options.encoding, .utf8)
        XCTAssertFalse(options.strictMode)
        XCTAssertNil(options.maxTrackCount)
        XCTAssertTrue(options.skipMissingFiles)
    }
    
    func testParseErrorDescriptions() {
        let fileNotFoundError = PlaylistParseError.fileNotFound("/test/path")
        XCTAssertTrue(fileNotFoundError.localizedDescription.contains("/test/path"))
        
        let invalidFormatError = PlaylistParseError.invalidFormat("unknown")
        XCTAssertTrue(invalidFormatError.localizedDescription.contains("unknown"))
    }
    
    func testM3UParserCanParse() {
        let m3uParser = M3UParser()
        
        let m3uURL = URL(fileURLWithPath: "/test/playlist.m3u")
        XCTAssertTrue(m3uParser.canParse(url: m3uURL))
        
        let m3u8URL = URL(fileURLWithPath: "/test/playlist.m3u8")
        XCTAssertTrue(m3uParser.canParse(url: m3u8URL))
        
        let xmlURL = URL(fileURLWithPath: "/test/playlist.xml")
        XCTAssertFalse(m3uParser.canParse(url: xmlURL))
    }
    
    func testTextParserCanParse() {
        let textParser = TextParser()
        
        let txtURL = URL(fileURLWithPath: "/test/playlist.txt")
        XCTAssertTrue(textParser.canParse(url: txtURL))
        
        let xmlURL = URL(fileURLWithPath: "/test/playlist.xml")
        XCTAssertFalse(textParser.canParse(url: xmlURL))
    }
    
    func testiTunesXMLParserCanParse() {
        let xmlParser = iTunesXMLParser()
        
        let xmlURL = URL(fileURLWithPath: "/test/playlist.xml")
        XCTAssertTrue(xmlParser.canParse(url: xmlURL))
        
        let m3uURL = URL(fileURLWithPath: "/test/playlist.m3u")
        XCTAssertFalse(xmlParser.canParse(url: m3uURL))
    }
}

