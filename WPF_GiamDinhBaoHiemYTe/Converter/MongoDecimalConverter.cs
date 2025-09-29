using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class MongoDecimalConverter : JsonConverter<decimal?>
    {
        public override decimal? ReadJson(JsonReader reader, Type objectType, decimal? existingValue, bool hasExistingValue, JsonSerializer serializer)
        {
            if (reader.TokenType == JsonToken.Null)
                return null;

            if (reader.TokenType == JsonToken.StartObject)
            {
                var jObject = JObject.Load(reader);
                if (jObject.TryGetValue("$numberDecimal", out var decimalValue))
                {
                    if (decimalValue.Type == JTokenType.String)
                    {
                        if (decimal.TryParse(decimalValue.ToString(), out decimal result))
                            return result;
                    }
                    else if (decimalValue.Type == JTokenType.Float)
                    {
                        return (decimal)decimalValue.Value<float>();
                    }
                }
                return null;
            }

            if (reader.TokenType == JsonToken.Float)
            {
                return (decimal)reader.Value;
            }

            if (reader.TokenType == JsonToken.Integer)
            {
                return (decimal)reader.Value;
            }

            if (reader.TokenType == JsonToken.String)
            {
                if (decimal.TryParse(reader.Value.ToString(), out decimal result))
                    return result;
            }

            return null;
        }

        public override void WriteJson(JsonWriter writer, decimal? value, JsonSerializer serializer)
        {
            if (value.HasValue)
            {
                writer.WriteValue(value.Value);
            }
            else
            {
                writer.WriteNull();
            }
        }
    }
}
