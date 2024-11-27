using UnityEngine;
public class Settings : MonoBehaviour
{
    public bool limitFps = true;
    public int fpsLimit = 30;

    private void Start()
    {
        Application.runInBackground = true;
        if (!limitFps) return;
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = fpsLimit;
    }
}