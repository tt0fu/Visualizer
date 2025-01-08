using Unity.Burst;

[BurstCompile(CompileSynchronously = true)]
public class CircularArray<T>
{
    public readonly T[] Array;
    private int Size { get; }
    public int Start { get; private set; }

    public CircularArray(int size)
    {
        Size = size;
        Array = new T[size];
        Start = 0;
    }

    public T this[int index]
    {
        get => Array[(Start + index) % Size];
        set => Array[(Start + index) % Size] = value;
    }

    public void Add(T[] items)
    {
        for (var i = 0; i < items.Length; i++)
        {
            Array[(Start + i) % Size] = items[i];
        }

        Start = (Start + items.Length) % Size;
    }
}