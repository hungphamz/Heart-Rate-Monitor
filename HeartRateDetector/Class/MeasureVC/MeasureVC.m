//
//  MeasureVC.m
//  HeartRateDetector
//
//  Created by Phạm Hùng on 12/31/16.
//  Copyright © 2016 Phạm Hùng. All rights reserved.
//

#import "MeasureVC.h"
#import "ButterworthFilter.h"
#import "HRDetector.h"


#import "FMDB/FMDB.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSUInteger, CURRENT_STATE) {
    STATE_PAUSED,
    STATE_SAMPLING
};

#define MIN_FRAMES_FOR_FILTER_TO_SETTLE 10

@interface MeasureVC () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureDevice *camera;
@property(nonatomic, strong) HRDetector *HRD;
@property(nonatomic, strong) ButterworthFilter *filter;
@property(nonatomic, assign) CURRENT_STATE currentState;
@property(nonatomic, assign) int validFrameCounter;

@property(nonatomic, strong) UIImage *blackHeart;
@property(nonatomic, strong) UIImage *redHeart;

@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIImageView *imgHeart;
@property (weak, nonatomic) IBOutlet UILabel *lblTip;
@property (weak, nonatomic) IBOutlet UILabel *lblFrame;

@end

@implementation MeasureVC
{
    BOOL    Started;
//    NSTimer *processTimer;
    NSTimer   *timer;
    float   currentHR;
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    [self resume];
//}
//
//-(void) viewWillDisappear:(BOOL)animated {
//    
//    [super viewWillDisappear:animated];
//    [self pause];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    Started = NO;
    currentHR = 0;

    _blackHeart = [UIImage imageNamed:@"Black_heart"];
    _redHeart = [UIImage imageNamed:@"Red_heart"];
    
    _btnStart.layer.cornerRadius = 5.0;
    _btnStart.clipsToBounds = YES;
    
    // alloc and init
    _HRD = [[HRDetector alloc] init];
    _filter = [[ButterworthFilter alloc] init];
    _lblTip.text = @"Put your finger on camera and tap Start button to measure";
}

// r,g,b values are from 0 to 1 // h = [0,360], s = [0,1], v = [0,1]
//	if s == 0, then h = -1 (undefined)
void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
    
    float min, max, delta;
    min = MIN( r, MIN(g, b ));
    max = MAX( r, MAX(g, b ));
    *v = max;
    delta = max - min;
    if( max != 0 )
        *s = delta / max;
    else {
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;
    else if( g == max )
        *h=2+(b-r)/delta;
    else
        *h=4+(r-g)/delta;
    *h *= 60;
    if( *h < 0 )
        *h += 360;
    
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if(self.currentState==STATE_PAUSED) {
        // reset our frame counter
        self.validFrameCounter=0;
        return;
    }
    // this is the image buffer
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    // access the data
    size_t width=CVPixelBufferGetWidth(cvimgRef);
    size_t height=CVPixelBufferGetHeight(cvimgRef);
    // get the raw image bytes
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    // and pull out the average rgb value of the frame
    float r=0,g=0,b=0;

    for(int y=0; y<height; y++) {
        for(int x=0; x<width*4; x+=4) {
            b+=buf[x];
            g+=buf[x+1];
            r+=buf[x+2];
        }
        buf+=bprow;
    }
    r/=255*(float) (width*height);
    g/=255*(float) (width*height);
    b/=255*(float) (width*height);
    
    // convert from rgb to hsv colourspace
    float h,s,v;
    RGBtoHSV(r, g, b, &h, &s, &v);
    // do a sanity check to see if a finger is placed over the camera
    if(s>0.5 && v>0.5) {

        // increment the valid frame count
        self.validFrameCounter++;
        // filter the hue value - the filter is a simple band pass filter that removes any DC component and any high frequency noise
        float filtered=[self.filter processValue:h];
        // have we collected enough frames for the filter to settle?
        if(self.validFrameCounter > MIN_FRAMES_FOR_FILTER_TO_SETTLE) {
            // add the new value to the pulse detector
            [self.HRD addNewValue:filtered atTime:CACurrentMediaTime()];
        }
        
    } else {
        
        self.validFrameCounter = 0;
        // clear the pulse detector - we only really need to do this once, just before we start adding valid samples
        [self.HRD reset];
    }

}

-(void) startCameraCapture {
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.5
                                             target: self
                                           selector:@selector(BlinkingMethod)
                                           userInfo: nil repeats:YES];
    self.session = [[AVCaptureSession alloc] init];
    Started = YES;
    self.camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOn;
        [self.camera unlockForConfiguration];
    }
    
    NSError *error=nil;
    
    AVCaptureInput* cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:&error];
    if (cameraInput == nil) {
        NSLog(@"Error to create camera capture:%@",error);
    }
    
    
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dispatch_queue_t captureQueue= dispatch_queue_create("captureQueue", NULL);

    [videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    
    // set the minimum acceptable frame rate to 10 fps
    videoOutput.minFrameDuration=CMTimeMake(1, 10);
    
    
    [self.session setSessionPreset:AVCaptureSessionPresetLow];
    
    // Add the input and output
    [self.session addInput:cameraInput];
    [self.session addOutput:videoOutput];
    
    // Start the session
    [self.session startRunning];
    

    self.currentState=STATE_SAMPLING;
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // update our UI on a timer every 0.1
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateHR) userInfo:nil repeats:YES];
}

-(void) stopCameraCapture {
    Started = NO;
    self.lblFrame.text = [NSString stringWithFormat:@"Captured Frames: 0%%"];
    [self.session stopRunning];
    self.session = nil;
    
    if ([timer isValid]) {
        [timer invalidate];
        timer = nil;
    }

    //
    
    [_imgHeart setImage:_blackHeart];
    
    
    [_btnStart setTitle:@"Start" forState:UIControlStateNormal];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}


-(void) BlinkingMethod {
    if ([_imgHeart.image isEqual:_blackHeart]) {
        [_imgHeart setImage:_redHeart];
    } else {
        [_imgHeart setImage:_blackHeart];
    }
}

-(void) updateHR {
    self.lblFrame.text = [NSString stringWithFormat:@"Captured Frames: %d%%", MIN(100, (100 * self.validFrameCounter)/MIN_FRAMES_FOR_FILTER_TO_SETTLE)];
    
    if(self.currentState==STATE_PAUSED)
        return;
    
    float avePeriod=[self.HRD getAverage];
    if(avePeriod != INVALID_PULSE_PERIOD) {
        currentHR = 60.0/avePeriod;
    }
}

#pragma mark - Button actions
- (IBAction)btnStartTapped:(UIButton *)sender {
    if (!Started) {
        
        [self performSelector:@selector(getResult) withObject:nil afterDelay:20.0];
        
        [_btnStart setTitle:@"Stop" forState:UIControlStateNormal];
        [self startCameraCapture];
    }
    else {
        
        [self stopCameraCapture];
        // Stop camera, navigate to state vc, save to history
    }
}


-(void) getResult {
    [self stopCameraCapture];
    
    NSString *str;
    if (currentHR < 60.0) {
        str = [NSString stringWithFormat:@"Your heart rate is low\nSave it to database?"];
    } else if (currentHR > 60.0 && currentHR < 90.0) {
        str = [NSString stringWithFormat:@"Your heart rate is normal\nSave it to database?"];
    } else {
        str = [NSString stringWithFormat:@"Your heart rate is fast\nSave it to database?"];
    }
    
    
    UIAlertController * alert = [UIAlertController
                                  alertControllerWithTitle:[NSString stringWithFormat:@"Result: %d BPM", (int)currentHR]
                                  message:str
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             //
                             NSDate *date = [NSDate date];
                             NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                             [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                             NSString *dateString = [dateFormatter stringFromDate:date];
                             //
                             NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                             NSString *documentsDir = [documentPaths objectAtIndex:0];
                             NSString *dbPath = [documentsDir   stringByAppendingPathComponent:@"dbheartrate.sqlite"];
                             
                             FMDatabase *database = [FMDatabase databaseWithPath:dbPath];
                             [database open];
                             [database executeUpdate:@"INSERT INTO dbheartrate (mdate, mhr) values (?, ?)", [NSString stringWithFormat:@"%@", dateString], [NSString stringWithFormat:@"%d", (int)currentHR], nil];
                             [database close];
                             
                             [alert dismissViewControllerAnimated:YES completion:nil];
 
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}


@end
