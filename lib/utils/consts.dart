/// ================================
/// Video & Frame Analysis Constants
/// ================================
library utils.consts;

// -------------------------------
// Frames Ranking Scoring Forumla Weights
// -------------------------------
const double sharpnessWeightConst = 0.30;
const double brigthnessWeightConst = 0.20;
const double contrastWeightConst = 0.10;
const double motionWeightConst = 0.10;
const double faceWeightConst = 0.40;

// -------------------------------
// Video duration thresholds (ms)
// -------------------------------
const int shortVideoDuration = 30 * 1000;      // < 30 seconds
const int midVideoDuration   = 1 * 60 * 1000;  // mid : 1min
const int longVideoDuration   = 2 * 60 * 1000;  // long : 2min

// -------------------------------
// Frame sampling intervals (ms)
// -------------------------------
const int shortDurationVideoSamplingTime = 250;   // for very short videos (100)
const int midDurationVideoSamplingTime   = 500;   // for medium videos (250)
const int longDurationVideoSamplingTime  = 1000;  // for long videos (>2 min)

// -------------------------------
// Ideal metric values (normalized)
// -------------------------------
const double brightnessIdealConst = 0.5;  // Brightness: 0 = black, 1 = white
const double contrastIdealConst   = 0.38; // Contrast: 0 = flat, 1 = max difference
const double sharpnessIdealConst  = 0.008; // Sharpness: normalized value (depends on image size)

// -------------------------------
// Maximum allowable distance from ideal
// -------------------------------
const double maxBrightnessDistanceConst = 0.5;  // brightness score drops to 0 at this distance
const double maxContrastDistanceConst   = 0.5;  // contrast score drops to 0 at this distance
const double maxSharpnessDistanceConst  = 0.01; // sharpness score drops to 0 at this distance