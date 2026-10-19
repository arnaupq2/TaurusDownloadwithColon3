#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>
#import <math.h>
#import <stdint.h>
#import "SGFillClip.h"

static const CGFloat kBackdropBlurRadius = 22.0, kEdgeFade = 0.035;
static const int32_t kLoopSeconds = 4, kFramesPerSecond = 24;

static CGColorSpaceRef fillColorSpace(void) {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    });
    return colorSpace;
}

static CIContext *fillCIContext(void) {
    static CIContext *context;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        context = [CIContext contextWithOptions:@{
            kCIContextUseSoftwareRenderer: @YES,
            kCIContextCacheIntermediates: @NO,
        }];
    });
    return context;
}

static CGContextRef bitmapContext(CGSize size) {
    size_t width = (size_t)round(size.width), height = (size_t)round(size.height);
    if (!width || !height) return NULL;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, fillColorSpace(),
                                                  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    if (context) CGContextClearRect(context, CGRectMake(0, 0, width, height));
    return context;
}

static UIColor *fillBackgroundColor(CGImageRef cover) {
    size_t width = CGImageGetWidth(cover), height = CGImageGetHeight(cover);
    if (width < 8 || height < 8) return UIColor.blackColor;
    CGRect sampleRect = CGRectMake(floor(width * 0.13), floor(height * 0.92),
                                   floor(width * 0.74), height - floor(height * 0.92));
    CGImageRef sample = CGImageCreateWithImageInRect(cover, sampleRect);
    if (!sample) return UIColor.blackColor;

    enum { kSampleSide = 8 };
    uint8_t pixels[kSampleSide * kSampleSide * 4] = {0};
    CGContextRef context = CGBitmapContextCreate(pixels, kSampleSide, kSampleSide, 8, kSampleSide * 4,
        fillColorSpace(), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    if (!context) {
        CGImageRelease(sample);
        return UIColor.blackColor;
    }
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, CGRectMake(0, 0, kSampleSide, kSampleSide), sample);
    CGContextRelease(context);
    CGImageRelease(sample);

    double red = 0, green = 0, blue = 0;
    for (NSUInteger index = 0; index < kSampleSide * kSampleSide; index++) {
        red += pixels[index * 4];
        green += pixels[index * 4 + 1];
        blue += pixels[index * 4 + 2];
    }
    CGFloat r = red / (kSampleSide * kSampleSide * 255.0);
    CGFloat g = green / (kSampleSide * kSampleSide * 255.0);
    CGFloat b = blue / (kSampleSide * kSampleSide * 255.0);
    UIColor *average = [UIColor colorWithRed:r green:g blue:b alpha:1];
    CGFloat hue = 0, saturation = 0, brightness = 0, alpha = 1;
    if (![average getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) return UIColor.blackColor;
    brightness = MIN(0.42, MAX(0.03, 0.9 * pow(brightness, 1.6)));
    saturation = MIN(saturation * 1.05, 1.0);
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

static CGImageRef blurredCoverForFrame(CGImageRef cover, CGFloat radius, CGSize size) CF_RETURNS_RETAINED {
    CIImage *input = [CIImage imageWithCGImage:cover];
    CGRect extent = input.extent;
    CGFloat side = MIN(extent.size.width, extent.size.height);
    CGRect square = CGRectMake(CGRectGetMidX(extent) - side / 2, CGRectGetMidY(extent) - side / 2, side, side);
    CIImage *artwork = [input imageByCroppingToRect:square];
    CGRect artworkExtent = artwork.extent;
    CGFloat frameHeight = artworkExtent.size.width * size.height / size.width;
    CGRect outputRect = CGRectMake(artworkExtent.origin.x,
                                   CGRectGetMidY(artworkExtent) - frameHeight / 2,
                                   artworkExtent.size.width, frameHeight);
    CIImage *output = [[artwork imageByClampingToExtent] imageByApplyingGaussianBlurWithSigma:radius];
    return [fillCIContext() createCGImage:output fromRect:outputRect];
}

static void drawFilling(CGContextRef context, CGImageRef image, CGRect rect) {
    CGFloat imageWidth = CGImageGetWidth(image), imageHeight = CGImageGetHeight(image);
    if (imageWidth <= 0 || imageHeight <= 0) return;
    CGFloat scale = MAX(rect.size.width / imageWidth, rect.size.height / imageHeight);
    CGSize drawn = CGSizeMake(imageWidth * scale, imageHeight * scale);
    CGRect destination = CGRectMake(rect.origin.x + (rect.size.width - drawn.width) / 2,
                                    rect.origin.y + (rect.size.height - drawn.height) / 2,
                                    drawn.width, drawn.height);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, destination, image);
}

static CGImageRef fullFrameLayer(CGImageRef image, CGSize size) CF_RETURNS_RETAINED {
    CGContextRef context = bitmapContext(size);
    if (!context) return NULL;
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    drawFilling(context, image, CGRectMake(0, 0, size.width, size.height));
    CGImageRef result = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return result;
}

static void addRampStop(CGFloat *components, CGFloat *locations, NSUInteger *count, CGFloat location, CGFloat alpha) {
    locations[*count] = location;
    components[*count * 4] = 1;
    components[*count * 4 + 1] = 1;
    components[*count * 4 + 2] = 1;
    components[*count * 4 + 3] = alpha;
    (*count)++;
}

static CGGradientRef alphaRamp(CGFloat start, CGFloat end, BOOL rising) {
    enum { kSteps = 14 };
    CGFloat components[(kSteps + 3) * 4], locations[kSteps + 3];
    NSUInteger count = 0;
    addRampStop(components, locations, &count, 0, rising ? 0 : 1);
    for (NSUInteger index = 0; index <= kSteps; index++) {
        CGFloat progress = (CGFloat)index / kSteps;
        CGFloat smooth = progress * progress * (3 - 2 * progress);
        addRampStop(components, locations, &count, start + (end - start) * progress, rising ? smooth : 1 - smooth);
    }
    addRampStop(components, locations, &count, 1, rising ? 1 : 0);
    return CGGradientCreateWithColorComponents(fillColorSpace(), components, locations, count);
}

static void applyRamp(CGContextRef context, CGFloat originY, CGFloat height, CGFloat start, CGFloat end, BOOL rising) {
    CGGradientRef gradient = alphaRamp(start, end, rising);
    if (!gradient) return;
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, originY + start * height), CGPointMake(0, originY + end * height),
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
}

static CGImageRef maskedLayer(CGImageRef image, CGSize size, CGRect artworkRect) CF_RETURNS_RETAINED {
    CGContextRef context = bitmapContext(size);
    if (!context) return NULL;
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextClipToRect(context, artworkRect);
    drawFilling(context, image, artworkRect);
    applyRamp(context, artworkRect.origin.y, artworkRect.size.height, 0, kEdgeFade, YES);
    applyRamp(context, artworkRect.origin.y, artworkRect.size.height, 1 - kEdgeFade, 1, NO);
    CGImageRef result = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return result;
}

CGImageRef SGFillClipFrame(CGImageRef cover, CGSize size) {
    if (!cover || size.width < 1 || size.height < 1) return NULL;
    CGFloat side = MIN(size.width, size.height);
    CGRect artworkRect = CGRectMake((size.width - side) / 2, (size.height - side) / 2, side, side);
    CGFloat blurScale = MAX(1.0, (CGFloat)CGImageGetWidth(cover) / 640.0);

    CGImageRef backdropBlur = blurredCoverForFrame(cover, kBackdropBlurRadius * blurScale, size);
    CGImageRef backdrop = backdropBlur ? fullFrameLayer(backdropBlur, size) : NULL;
    if (backdropBlur) CGImageRelease(backdropBlur);
    CGImageRef foreground = maskedLayer(cover, size, artworkRect);
    if (!backdrop || !foreground) {
        if (backdrop) CGImageRelease(backdrop);
        if (foreground) CGImageRelease(foreground);
        return NULL;
    }

    CGContextRef context = bitmapContext(size);
    if (!context) {
        CGImageRelease(backdrop);
        CGImageRelease(foreground);
        return NULL;
    }
    CGContextSetFillColorWithColor(context, fillBackgroundColor(cover).CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), backdrop);
    CGImageRelease(backdrop);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), foreground);
    CGImageRelease(foreground);
    CGImageRef result = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return result;
}

BOOL SGFillClipWriteFrame(NSURL *file, CGImageRef frame, CGSize size) {
    if (!file || !frame || size.width < 1 || size.height < 1) return NO;
    NSURL *partial = [file URLByAppendingPathExtension:@"partial"];
    [NSFileManager.defaultManager removeItemAtURL:partial error:nil];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:partial fileType:AVFileTypeMPEG4 error:nil];
    if (!writer) {
        [NSFileManager.defaultManager removeItemAtURL:partial error:nil];
        return NO;
    }
    int32_t width = (int32_t)round(size.width), height = (int32_t)round(size.height);
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:@{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: @(width),
        AVVideoHeightKey: @(height),
        AVVideoCompressionPropertiesKey: @{AVVideoAverageBitRateKey: @(2000000),
                                           AVVideoMaxKeyFrameIntervalKey: @(kFramesPerSecond)},
    }];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
        assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:@{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferWidthKey: @(width),
            (id)kCVPixelBufferHeightKey: @(height),
        }];
    if (![writer canAddInput:input]) {
        [NSFileManager.defaultManager removeItemAtURL:partial error:nil];
        return NO;
    }
    [writer addInput:input];
    if (![writer startWriting]) {
        [NSFileManager.defaultManager removeItemAtURL:partial error:nil];
        return NO;
    }
    [writer startSessionAtSourceTime:kCMTimeZero];

    BOOL ok = YES;
    int32_t frameCount = kLoopSeconds * kFramesPerSecond;
    for (int32_t index = 0; index < frameCount && ok; index++) {
        while (!input.readyForMoreMediaData && writer.status == AVAssetWriterStatusWriting) {
            [NSThread sleepForTimeInterval:0.002];
        }
        CVPixelBufferRef buffer = NULL;
        ok = writer.status == AVAssetWriterStatusWriting && adaptor.pixelBufferPool
            && CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &buffer) == kCVReturnSuccess;
        if (!ok) break;
        CVPixelBufferLockBaseAddress(buffer, 0);
        CGContextRef context = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(buffer), (size_t)width, (size_t)height,
            8, CVPixelBufferGetBytesPerRow(buffer), fillColorSpace(),
            kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
        ok = context != NULL;
        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), frame);
            CGContextRelease(context);
        }
        CVPixelBufferUnlockBaseAddress(buffer, 0);
        if (ok) ok = [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(index, kFramesPerSecond)];
        CVPixelBufferRelease(buffer);
    }
    if (!ok) {
        [writer cancelWriting];
        [NSFileManager.defaultManager removeItemAtURL:partial error:nil];
        return NO;
    }
    [input markAsFinished];
    [writer endSessionAtSourceTime:CMTimeMake(kLoopSeconds, 1)];
    dispatch_semaphore_t written = dispatch_semaphore_create(0);
    [writer finishWritingWithCompletionHandler:^{ dispatch_semaphore_signal(written); }];
    dispatch_semaphore_wait(written, DISPATCH_TIME_FOREVER);
    if (writer.status != AVAssetWriterStatusCompleted) {
        [NSFileManager.defaultManager removeItemAtURL:partial error:nil];
        return NO;
    }
    [NSFileManager.defaultManager removeItemAtURL:file error:nil];
    return [NSFileManager.defaultManager moveItemAtURL:partial toURL:file error:nil];
}
