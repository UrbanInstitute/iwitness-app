#import "AudioPlayerProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AudioPlayerProviderSpec)

describe(@"AudioPlayerProvider", ^{
    __block AudioPlayerProvider *provider;

    beforeEach(^{
        provider = [[AudioPlayerProvider alloc] init];
    });

    describe(@"providing audio players", ^{
        __block NSURL *soundURL;
        __block AVAudioPlayer *audioPlayer;

        beforeEach(^{
            soundURL = [[NSBundle mainBundle] URLForResource:@"witness_preparation" withExtension:@"m4a"];
            audioPlayer = [provider audioPlayerWithSoundURL:soundURL];
        });

        it(@"should provide a correctly-configured audio player", ^{
            audioPlayer.url should equal(soundURL);
        });
    });
});

SPEC_END
