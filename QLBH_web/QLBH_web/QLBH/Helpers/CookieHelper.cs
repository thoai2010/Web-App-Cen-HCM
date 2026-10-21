using Newtonsoft.Json;
using System;
using System.Web;

namespace QLBH.Helpers
{
    public static class CookieHelper
    {
        public static void Save<T>(string key, T data, int days = 7)
        {
            var json = JsonConvert.SerializeObject(data);
            var cookie = new HttpCookie(key, json)
            {
                Expires = DateTime.Now.AddDays(days)
            };
            HttpContext.Current.Response.Cookies.Add(cookie);
        }

        public static T Get<T>(string key)
        {
            var cookie = HttpContext.Current.Request.Cookies[key];
            if (cookie == null) return default;
            return JsonConvert.DeserializeObject<T>(cookie.Value);
        }

        public static void Remove(string key)
        {
            var cookie = new HttpCookie(key)
            {
                Expires = DateTime.Now.AddDays(-1)
            };
            HttpContext.Current.Response.Cookies.Add(cookie);
        }
    }
}
