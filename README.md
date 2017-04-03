# aacEncodingTest
This repo contains my experiments of making VoIP-calls implementation in Objective C.

I used my company serverside (written on PHP) for establishing SIP-connections between two devices: parent (can only call) and child (can only receive). The most complicated thing was audio decoding/encoding. All data is transfered in AAC LC format with ADTS headers. Finally, I made decoding by writing custom data source for StreamingKit library, made by Thong Nguen. For encoding, I used class written by Criss Ballinger.

Link to Thong Nguen repo: https://github.com/tumtumtum/StreamingKit

Link to Criss Ballinger repo: https://github.com/chrisballinger/FFmpeg-iOS-Encoder
