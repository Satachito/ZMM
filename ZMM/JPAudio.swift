import AVFAudio

func
AnalyzeWAV( _ wav: Data ) {

	let
	int16Header = Array(
		wav.withUnsafeBytes {
			UnsafeBufferPointer(
				start: $0.baseAddress!.assumingMemoryBound( to: Int16.self )
			,   count: 22
			)
		}
	)
	guard int16Header[ 10 ] == 1	else { fatalError() }	//	"audioFormat"
	guard int16Header[ 11 ] == 1	else { fatalError() }	//	"numChannels"
	guard int16Header[ 17 ] == 16	else { fatalError() }	//	"bitsPerSample"
//	print( int16Header[ 16 ], "blockAlign" )

	let
	int32Header = Array(
		wav.withUnsafeBytes {
			UnsafeBufferPointer(
				start: $0.baseAddress!.assumingMemoryBound( to: Int32.self )
			,   count: 11
			)
		}
	)
	guard int32Header[ 0 ] == 0x46464952	else { fatalError() }	//	"RIFF"
	guard int32Header[ 1 ] == wav.count - 8	else { fatalError() }	//	"RIFF SIZE, file size - 8"
	guard int32Header[ 2 ] == 0x45564157	else { fatalError() }	//	"WAVE"
	guard int32Header[ 3 ] == 0x20746d66	else { fatalError() }	//	"fmt "
	guard int32Header[ 6 ] == 24000			else { fatalError() }	//	sampleRate
	guard int32Header[ 9 ] == 0x61746164	else { fatalError() }	//	"data"

//	print( int32Header[  4 ], "subchunk1Size" )
//	print( int32Header[  7 ], "byteRate" )
	print( int32Header[ 10 ], "dataSize" )
}
//	GENERIC
/*
class
AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    var audioPlayer: AVAudioPlayer?

    func
    Play( wav: Data ) throws {
		audioPlayer = try AVAudioPlayer( data: wav )
		audioPlayer?.play()
		isPlaying = true
    }

    func
    Stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

struct
WAVPlayerV: View {
    @State		var
	audioPlayer	: AVAudioPlayer?
	@Binding	var
	wav			: Data? {
		didSet {
			if let wav = wav {
				do {
					audioPlayer = try AVAudioPlayer( data: wav )
					audioPlayer?.delegate = delegate
				} catch {
					print( error )
				}
				
				
				

	class
	Delegate: NSObject, @preconcurrency AVAudioPlayerDelegate {
		var
		parent	: WAVPlayerV
		init( _ parent: WAVPlayerV ) {
			self.parent = parent
		}
		@MainActor func
		audioPlayerDidFinishPlaying( _ player: AVAudioPlayer, successfully flag: Bool ) {
			parent.audioPlayer = nil
		}
	}
	private		var
	delegate	: Delegate
	
	var
	body: some View {
		if let audioPlayer = audioPlayer {
		if let wav = self.wav {
			SystemImageB( "play" ) {
				do {
					audioPlayer = try AVAudioPlayer( data: wav )
					audioPlayer?.delegate = delegate
					audioPlayer?.play()
				} catch {
					print( error )
				}
			}
		}
		if
	}
}
*/

