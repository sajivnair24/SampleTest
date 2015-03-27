//
//  ViewController.m
//  SampleTest
//
//  Created by Sanket on 25/03/15.
//  Copyright (c) 2015 Intelliswift. All rights reserved.
//

#import "ViewController.h"
#import "AudioToolbox/AudioToolbox.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    OSStatus err = noErr;
    
    ExtAudioFileRef audiofile;
    NSURL *theURL = [NSURL URLWithString:@"/Users/intelliswift/Downloads/test.m4a"];
    NSURL *theURL2 = [NSURL URLWithString:@"/Users/intelliswift/Downloads/test4.m4a"];
    ExtAudioFileOpenURL((__bridge CFURLRef)theURL, &audiofile);
    assert(audiofile);
    
    // get some info about the file's format.
    AudioStreamBasicDescription fileFormat;
    UInt32 size = sizeof(fileFormat);
    err = ExtAudioFileGetProperty(audiofile, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat);
    
    // we'll need to know what type of file it is later when we write
    AudioFileID aFile;
    size = sizeof(aFile);
    err = ExtAudioFileGetProperty(audiofile, kExtAudioFileProperty_AudioFile, &size, &aFile);
    AudioFileTypeID fileType;
    size = sizeof(fileType);
    err = AudioFileGetProperty(aFile, kAudioFilePropertyFileFormat, &size, &fileType);
    
    
    // tell the ExtAudioFile API what format we want samples back in
    AudioStreamBasicDescription clientFormat;
    bzero(&clientFormat, sizeof(clientFormat));
    clientFormat.mChannelsPerFrame = fileFormat.mChannelsPerFrame;
    clientFormat.mBytesPerFrame = 4;
    clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame;
    clientFormat.mFramesPerPacket = 1;
    clientFormat.mBitsPerChannel = 32;
    clientFormat.mFormatID = kAudioFormatLinearPCM;
    //clientFormat.mSampleRate = fileFormat.mSampleRate;
    clientFormat.mSampleRate = clientFormat.mSampleRate * 1.2;
    clientFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    err = ExtAudioFileSetProperty(audiofile, kExtAudioFileProperty_ClientDataFormat, sizeof(clientFormat), &clientFormat);
    
    // find out how many frames we need to read
    SInt64 numFrames = 0;
    size = sizeof(numFrames);
    err = ExtAudioFileGetProperty(audiofile, kExtAudioFileProperty_FileLengthFrames, &size, &numFrames);
    
    // create the buffers for reading in data
    AudioBufferList *bufferList = malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * (clientFormat.mChannelsPerFrame - 1));
    bufferList->mNumberBuffers = clientFormat.mChannelsPerFrame;
    for (int ii=0; ii < bufferList->mNumberBuffers; ++ii) {
        bufferList->mBuffers[ii].mDataByteSize = sizeof(float) * numFrames;
        bufferList->mBuffers[ii].mNumberChannels = 1;
        bufferList->mBuffers[ii].mData = malloc(bufferList->mBuffers[ii].mDataByteSize);
    }
    
    // read in the data
    UInt32 rFrames = (UInt32)numFrames;
    err = ExtAudioFileRead(audiofile, &rFrames, bufferList);
    
    // close the file
    err = ExtAudioFileDispose(audiofile);
    
    // process the audio
    for (int ii=0; ii < bufferList->mNumberBuffers; ++ii) {
        float *fBuf = (float *)bufferList->mBuffers[ii].mData;
        for (int jj=0; jj < rFrames; ++jj) {
            //*fBuf = *fBuf * 5.0f;
            fBuf++;
        }
    }
    
    // open the file for writing
    err = ExtAudioFileCreateWithURL((__bridge CFURLRef)theURL2, fileType, &fileFormat, NULL, kAudioFileFlags_EraseFile, &audiofile);
    
    // tell the ExtAudioFile API what format we'll be sending samples in
    err = ExtAudioFileSetProperty(audiofile, kExtAudioFileProperty_ClientDataFormat, sizeof(clientFormat), &clientFormat);
    
    // write the data
    err = ExtAudioFileWrite(audiofile, rFrames, bufferList);
    
    // close the file
    ExtAudioFileDispose(audiofile);
    
    // destroy the buffers
    for (int ii=0; ii < bufferList->mNumberBuffers; ++ii) {
        free(bufferList->mBuffers[ii].mData);
    }
    free(bufferList);
    bufferList = NULL;
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
