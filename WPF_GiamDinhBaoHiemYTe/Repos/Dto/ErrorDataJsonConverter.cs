using System.Text.Json;
using System.Text.Json.Serialization;

namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    /// <summary>
    /// Cho phép errors trả về dạng chuỗi (sai format) vẫn deserialize được, gán "chưa xác định" thay vì làm fail cả response.
    /// </summary>
    public class ErrorDataJsonConverter : JsonConverter<errorData>
    {
        private const string FallbackError = "chưa xác định";

        public override errorData Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.String)
            {
                _ = reader.GetString();
                return new errorData { Error = FallbackError };
            }

            if (reader.TokenType == JsonTokenType.StartObject)
            {
                int? id = null;
                string error = string.Empty;
                while (reader.Read())
                {
                    if (reader.TokenType == JsonTokenType.EndObject)
                        break;
                    if (reader.TokenType != JsonTokenType.PropertyName)
                        continue;
                    var propName = reader.GetString()?.ToLowerInvariant();
                    reader.Read();
                    if (propName == "id")
                    {
                        if (reader.TokenType == JsonTokenType.Number && reader.TryGetInt32(out var idVal))
                            id = idVal;
                        else if (reader.TokenType == JsonTokenType.Null)
                            id = null;
                    }
                    else if (propName == "error")
                    {
                        error = reader.GetString() ?? string.Empty;
                    }
                }
                return new errorData { Id = id, Error = error };
            }

            return new errorData { Error = FallbackError };
        }

        public override void Write(Utf8JsonWriter writer, errorData value, JsonSerializerOptions options)
        {
            writer.WriteStartObject();
            if (value.Id.HasValue)
                writer.WriteNumber("id", value.Id.Value);
            writer.WriteString("error", value.Error ?? string.Empty);
            writer.WriteEndObject();
        }
    }
}
