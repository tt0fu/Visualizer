// using UnityEngine;
//
// [RequireComponent(typeof(AudioSource))]
// public class MicrophoneCapture : MonoBehaviour
// {
//     private AudioSource _audioSource;
//     private const string DeviceName = null;
//     private const int Length = 10;
//     private AudioClip _microphoneClip;
//     private int _lastPos, _pos;
//
//     private void Start()
//     {
//         _audioSource = GetComponent<AudioSource>();
//         Microphone.GetDeviceCaps(DeviceName, out _, out var maxFreq);
//         // _audioSource.clip = Microphone.Start(DeviceName, true, Length, maxFreq);
//         // _audioSource.loop = true;
//         // while (!(Microphone.GetPosition(DeviceName) > 0))
//         // {
//         // }
//         //
//         // _audioSource.Play();
//         _microphoneClip = Microphone.Start(DeviceName, true, Length, maxFreq);
//
//         _audioSource.clip = AudioClip.Create("Microphone", Length * maxFreq, _microphoneClip.channels, maxFreq, false);
//         _audioSource.loop = true;
//     }
//
//     // Update is called once per frame
//     private void Update()
//     {
//         if ((_pos = Microphone.GetPosition(null)) <= 0)
//         {
//             return;
//         }
//
//         if (_lastPos > _pos)
//         {
//             _lastPos = 0;
//         }
//
//         if (_pos - _lastPos <= 0)
//         {
//             return;
//         }
//
//         var sample = new float[(_pos - _lastPos) * _microphoneClip.channels];
//         _microphoneClip.GetData(sample, _lastPos);
//         _audioSource.clip.SetData(sample, _lastPos);
//         if (!_audioSource.isPlaying)
//         {
//             _audioSource.Play();
//         }
//
//         _lastPos = _pos;
//     }
//
//     private void OnDestroy()
//     {
//         Microphone.End(null);
//     }
// }