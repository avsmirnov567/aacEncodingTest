# aacEncodingTest
This repo contains my experiments of recording audio to AAC LC format and playback it.

For encoding, I used class written by Criss Ballinger. Decoding was solved by writing custom data source for StreamingKit library, made by Thong Nguen. It was neccessary for me to work with streams only, because I have planned to use this project in VoIP-calls implementation.

Link to Thong Nguen repo: https://github.com/tumtumtum/StreamingKit

Link to Criss Ballinger repo: https://github.com/chrisballinger/FFmpeg-iOS-Encoder
