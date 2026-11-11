#ifndef EXOCAMERA_WHISPER_BRIDGE_H
#define EXOCAMERA_WHISPER_BRIDGE_H

#include <stdbool.h>
#include <stdint.h>

// Keep whisper/ggml declarations out of Swift: llama embeds a different ggml version.
typedef struct ExoCameraWhisperContext ExoCameraWhisperContext;
typedef bool (*ExoCameraWhisperAbort)(void *user_data);

ExoCameraWhisperContext *ExoCameraWhisperLoad(const char *model_path);
void ExoCameraWhisperFree(ExoCameraWhisperContext *context);
bool ExoCameraWhisperSupportsLanguage(const char *language);
int32_t ExoCameraWhisperTranscribe(ExoCameraWhisperContext *context, const float *samples, int32_t count,
                                const char *language, int32_t threads, ExoCameraWhisperAbort abort, void *user_data);
int32_t ExoCameraWhisperSegmentCount(ExoCameraWhisperContext *context);
const char *ExoCameraWhisperSegmentText(ExoCameraWhisperContext *context, int32_t index);
float ExoCameraWhisperNoSpeechProbability(ExoCameraWhisperContext *context, int32_t index);

#endif
