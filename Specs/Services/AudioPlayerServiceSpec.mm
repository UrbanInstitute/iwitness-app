#import "AudioPlayerService.h"
#import "AudioPlayerProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AudioPlayerServiceSpec)

describe(@"AudioPlayerService", ^{
    __block AudioPlayerService *service;
    __block AudioPlayerProvider *provider;
    __block KSPromise *promise;

    beforeEach(^{
        provider = nice_fake_for([AudioPlayerProvider class]);
        service = [[AudioPlayerService alloc] initWithAudioPlayerProvider:provider];
    });

    describe(@"playing a sound", ^{
        __block AVAudioPlayer *audioPlayer;
        __block NSURL *expectedSoundURL;

        beforeEach(^{
            expectedSoundURL = [[NSBundle mainBundle] URLForResource:@"witness_preparation" withExtension:@"m4a"];
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:expectedSoundURL error:nil];
            spy_on(audioPlayer);
            audioPlayer stub_method(@selector(play));

            provider stub_method(@selector(audioPlayerWithSoundURL:)).with(expectedSoundURL).and_return(audioPlayer);
            promise = [service playSoundNamed:@"witness_preparation"];
        });

        it(@"should tell the audio player to play the sound", ^{
            audioPlayer should have_received(@selector(play));
        });

        describe(@"when playback finishes", ^{
            beforeEach(^{
                [audioPlayer.delegate audioPlayerDidFinishPlaying:audioPlayer successfully:YES];
            });

            it(@"should fulfill the promise", ^{
                promise.fulfilled should be_truthy;
            });
        });

        describe(@"stopping playback", ^{
            beforeEach(^{
                [service stopPlaying];
            });

            it(@"should stop playback", ^{
                audioPlayer should have_received(@selector(stop));
            });
        });
    });

    describe(@"localizing audio prompts", ^{
        __block NSURL *URLForLocalizedAudioPrompt;

        afterEach(^{
            [WitnessLocalization reset];
        });

        context(@"when the language is Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                URLForLocalizedAudioPrompt = [WitnessLocalization URLForAudioPromptWithName:@"witness_preparation"];
                [service playSoundNamed:@"witness_preparation"];
            });

            it(@"should pass the correct URL to the provider", ^{
                provider should have_received(@selector(audioPlayerWithSoundURL:)).with(URLForLocalizedAudioPrompt);
            });
        });

        context(@"when the language is English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                URLForLocalizedAudioPrompt = [WitnessLocalization URLForAudioPromptWithName:@"witness_preparation"];
                [service playSoundNamed:@"witness_preparation"];
            });

            it(@"should pass the correct URL to the provider", ^{
                provider should have_received(@selector(audioPlayerWithSoundURL:)).with(URLForLocalizedAudioPrompt);
            });
        });
    });
});

SPEC_END
