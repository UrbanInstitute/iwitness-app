#import <CoreMedia/CoreMedia.h>

#import "ComparatorsBase.h"

namespace Cedar { namespace Matchers { namespace Comparators {
    template<typename U>
    bool compare_equal(CMTimeRange const actualValue, const U & expectedValue) {
        return CMTimeRangeEqual(actualValue, expectedValue);
    }
}}}

#import "StringifiersBase.h"

namespace Cedar { namespace Matchers { namespace Stringifiers {
    inline NSString * string_for(const CMTimeRange value) {
        return [NSString stringWithFormat:@"%lld/%d (duration %lld/%d)", value.start.value, value.start.timescale, value.duration.value, value.duration.timescale];
    }
}}}
