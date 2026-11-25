package com.example.helloworld;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
public class HelloController {

    private final JdbcTemplate jdbc;

    public HelloController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/")
    public String hello() {
        return "Hello World from Spring Boot!";
    }

    @GetMapping("/db")
    public String database() {
        Integer result = jdbc.queryForObject(
            "SELECT 1", Integer.class
        );
        return "Database connection successful: " + result;
    }

    @PostMapping("/messages")
    public String addMessage(@RequestParam("content") String content) {
        jdbc.update(
            "INSERT INTO messages (content) VALUES (?)",
            content
        );
        return "Message saved: " + content;
    }

    @GetMapping("/messages")
    public List<Map<String, Object>> messages() {
        return jdbc.queryForList("SELECT * FROM messages");
    }
}
