const state = {
  page: "overview",
  data: {},
  search: "",
  grade: "all",
};

const pageDetails = {
  overview: {
    title: "Good day",
    description: "Here’s what’s happening at your school today.",
  },
  students: {
    title: "Students",
    description: "Browse student records and academic progress.",
  },
  courses: {
    title: "Courses",
    description: "Your courses, teaching staff, and class enrollment.",
  },
  results: {
    title: "Results",
    description: "Student grades across every course and term.",
  },
  attendance: {
    title: "Attendance",
    description: "A day-by-day record of student attendance.",
  },
};

const pageContent = document.querySelector("#page-content");
const notice = document.querySelector("#notice");

function escapeHTML(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[character]);
}

function initials(firstName, lastName) {
  return `${firstName?.[0] ?? ""}${lastName?.[0] ?? ""}`.toUpperCase();
}

function formatName(row) {
  return `${row.first_name} ${row.last_name}`;
}

function gradeMarkup(grade) {
  if (grade === null || grade === undefined) {
    return '<span class="muted-cell">Not graded</span>';
  }
  const low = Number(grade) < 60 ? " grade-low" : "";
  return `<span class="grade-pill${low}">${escapeHTML(grade)}%</span>`;
}

function emptyTableRow(message, columns) {
  return `<tr><td class="empty-state" colspan="${columns}">${escapeHTML(message)}</td></tr>`;
}

function studentTable(students) {
  if (!students.length) {
    return `<div class="empty-state">No students match your search.</div>`;
  }
  return `
    <div class="table-wrap">
      <table>
        <thead><tr><th>STUDENT</th><th>GRADE</th><th>COURSES</th><th>AVG. RESULT</th><th>ATTENDANCE</th></tr></thead>
        <tbody>${students.map((student) => `
          <tr>
            <td><div class="student-cell"><span class="student-avatar">${escapeHTML(initials(student.first_name, student.last_name))}</span>
              <span><span class="student-name">${escapeHTML(formatName(student))}</span><span class="student-email">${escapeHTML(student.email || "No email on file")}</span></span>
            </div></td>
            <td>Grade ${escapeHTML(student.grade_level)}</td>
            <td>${escapeHTML(student.course_count)}</td>
            <td>${gradeMarkup(student.average_grade)}</td>
            <td>${student.attendance_rate === null ? '<span class="muted-cell">No records</span>' : `${escapeHTML(student.attendance_rate)}%`}</td>
          </tr>`).join("")}</tbody>
      </table>
    </div>`;
}

function courseRows(courses) {
  if (!courses.length) {
    return '<div class="empty-state">No courses found.</div>';
  }
  return `<div class="course-list">${courses.map((course) => `
    <div class="course-row">
      <span class="course-mark">${escapeHTML(course.course_code.slice(0, 2))}</span>
      <span class="course-info"><strong>${escapeHTML(course.title)}</strong><small>${escapeHTML(course.course_code)} · ${course.teacher_first_name ? `Taught by ${escapeHTML(`${course.teacher_first_name} ${course.teacher_last_name}`)}` : "Teacher not assigned"}</small></span>
      <span class="course-students">${escapeHTML(course.student_count)} students</span>
    </div>`).join("")}</div>`;
}

function resultsTable(results) {
  if (!results.length) return emptyTableRow("No results found.", 5);
  return results.map((result) => `
    <tr>
      <td><span class="student-name">${escapeHTML(formatName(result))}</span></td>
      <td>Grade ${escapeHTML(result.grade_level)}</td>
      <td>${escapeHTML(result.course_code)} · ${escapeHTML(result.course_title)}</td>
      <td>${escapeHTML(result.semester)}</td>
      <td>${gradeMarkup(result.final_grade)}</td>
    </tr>`).join("");
}

function attendanceTable(records) {
  if (!records.length) return emptyTableRow("No attendance records found.", 5);
  return records.map((record) => `
    <tr>
      <td>${escapeHTML(record.date)}</td>
      <td><span class="student-name">${escapeHTML(formatName(record))}</span></td>
      <td>Grade ${escapeHTML(record.grade_level)}</td>
      <td>${escapeHTML(record.course_code)} · ${escapeHTML(record.course_title)}</td>
      <td><span class="status-pill${record.present ? "" : " absent"}">${record.present ? "Present" : "Absent"}</span></td>
    </tr>`).join("");
}

function statCard(label, value, caption, icon) {
  return `<article class="stat-card">
    <div class="stat-top"><span>${escapeHTML(label)}</span><span class="stat-icon">${icon}</span></div>
    <div class="stat-value">${escapeHTML(value)}</div>
    <span class="stat-caption">${escapeHTML(caption)}</span>
  </article>`;
}

function renderOverview() {
  const summary = state.data.overview;
  const students = state.data.students;
  const courses = state.data.courses;
  return `
    <section class="stats-grid">
      ${statCard("Total students", summary.students, "Enrolled in your school", "♧")}
      ${statCard("Active courses", summary.courses, "Across all grade levels", "▤")}
      ${statCard("Teaching staff", summary.teachers, "Teachers on your roster", "♙")}
      ${statCard("Attendance rate", `${summary.attendance_rate ?? 0}%`, `${summary.attendance_records} records on file`, "◷")}
    </section>
    <section class="dashboard-grid">
      <article class="panel">
        <div class="panel-header"><div><h2 class="panel-title">Recent students</h2><p class="panel-subtitle">A snapshot of student records</p></div><button class="text-button" data-navigate="students">View all →</button></div>
        ${studentTable(students.slice(0, 5))}
      </article>
      <article class="panel">
        <div class="panel-header"><div><h2 class="panel-title">Your courses</h2><p class="panel-subtitle">Course enrollment at a glance</p></div><button class="text-button" data-navigate="courses">View all →</button></div>
        ${courseRows(courses)}
      </article>
    </section>
    <section class="panel">
      <div class="panel-header"><div><h2 class="panel-title">Latest results</h2><p class="panel-subtitle">Recent student grades</p></div><button class="text-button" data-navigate="results">All results →</button></div>
      <div class="table-wrap"><table><thead><tr><th>STUDENT</th><th>GRADE</th><th>COURSE</th><th>TERM</th><th>RESULT</th></tr></thead>
        <tbody>${resultsTable(state.data.results.slice(0, 5))}</tbody></table></div>
    </section>`;
}

function renderStudents() {
  const grades = [...new Set(state.data.students.map((student) => student.grade_level))].sort((a, b) => a - b);
  const filtered = state.data.students.filter((student) => {
    const text = `${student.first_name} ${student.last_name} ${student.email ?? ""}`.toLowerCase();
    return text.includes(state.search.toLowerCase())
      && (state.grade === "all" || String(student.grade_level) === state.grade);
  });
  return `<section class="panel">
    <div class="table-toolbar">
      <span class="toolbar-note">${filtered.length} student${filtered.length === 1 ? "" : "s"}</span>
      <div class="toolbar-controls">
        <input class="search-input" id="student-search" type="search" placeholder="Search students…" value="${escapeHTML(state.search)}" aria-label="Search students">
        <select class="filter-select" id="grade-filter" aria-label="Filter by grade">
          <option value="all">All grades</option>
          ${grades.map((grade) => `<option value="${escapeHTML(grade)}"${String(grade) === state.grade ? " selected" : ""}>Grade ${escapeHTML(grade)}</option>`).join("")}
        </select>
      </div>
    </div>
    ${studentTable(filtered)}
  </section>`;
}

function renderCourses() {
  return `<section class="panel">
    <div class="panel-header"><div><h2 class="panel-title">All courses</h2><p class="panel-subtitle">${state.data.courses.length} courses in the database</p></div></div>
    ${courseRows(state.data.courses)}
  </section>`;
}

function renderResults() {
  return `<section class="panel">
    <div class="panel-header"><div><h2 class="panel-title">Student results</h2><p class="panel-subtitle">${state.data.results.length} course enrollment results</p></div></div>
    <div class="table-wrap"><table><thead><tr><th>STUDENT</th><th>GRADE</th><th>COURSE</th><th>TERM</th><th>RESULT</th></tr></thead><tbody>${resultsTable(state.data.results)}</tbody></table></div>
  </section>`;
}

function renderAttendance() {
  return `<section class="panel">
    <div class="panel-header"><div><h2 class="panel-title">Attendance records</h2><p class="panel-subtitle">${state.data.attendance.length} records in the database</p></div></div>
    <div class="table-wrap"><table><thead><tr><th>DATE</th><th>STUDENT</th><th>GRADE</th><th>COURSE</th><th>STATUS</th></tr></thead><tbody>${attendanceTable(state.data.attendance)}</tbody></table></div>
  </section>`;
}

function render() {
  const details = pageDetails[state.page];
  document.querySelector("#breadcrumb-current").textContent = details.title;
  document.querySelector("#page-title").innerHTML = `${escapeHTML(details.title)}${state.page === "overview" ? ' <span class="heading-wave">✳</span>' : ""}`;
  document.querySelector("#page-description").textContent = details.description;
  document.querySelector("#student-nav-count").textContent = state.data.students.length;
  document.querySelectorAll(".nav-item").forEach((button) => {
    button.classList.toggle("active", button.dataset.page === state.page);
  });

  if (state.page === "overview") pageContent.innerHTML = renderOverview();
  if (state.page === "students") pageContent.innerHTML = renderStudents();
  if (state.page === "courses") pageContent.innerHTML = renderCourses();
  if (state.page === "results") pageContent.innerHTML = renderResults();
  if (state.page === "attendance") pageContent.innerHTML = renderAttendance();

  document.querySelector("#student-search")?.addEventListener("input", (event) => {
    state.search = event.target.value;
    const cursor = event.target.selectionStart;
    render();
    const search = document.querySelector("#student-search");
    search.focus();
    search.setSelectionRange(cursor, cursor);
  });
  document.querySelector("#grade-filter")?.addEventListener("change", (event) => {
    state.grade = event.target.value;
    render();
  });
}

async function loadDashboard() {
  const endpoints = ["overview", "students", "courses", "results", "attendance"];
  try {
    const responses = await Promise.all(endpoints.map(async (endpoint) => {
      const response = await fetch(`/api/${endpoint}`, { cache: "no-store" });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || `Could not load ${endpoint}.`);
      return [endpoint, data];
    }));
    state.data = Object.fromEntries(responses);
    notice.hidden = true;
    render();
    document.querySelector("#last-updated").textContent = `Updated ${new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
  } catch (error) {
    notice.textContent = `Dashboard couldn’t load: ${error.message}`;
    notice.hidden = false;
    pageContent.innerHTML = '<div class="empty-state">Check the local server terminal and your SQLite database, then refresh.</div>';
    document.querySelector("#last-updated").textContent = "Could not connect";
  }
}

function navigate(page) {
  if (!pageDetails[page]) return;
  state.page = page;
  state.search = "";
  state.grade = "all";
  render();
}

document.querySelectorAll(".nav-item").forEach((button) => {
  button.addEventListener("click", () => navigate(button.dataset.page));
});
document.querySelector("#page-content").addEventListener("click", (event) => {
  const button = event.target.closest("[data-navigate]");
  if (button) navigate(button.dataset.navigate);
});
document.querySelector("#view-students-button").addEventListener("click", () => navigate("students"));
document.querySelector("#refresh-button").addEventListener("click", loadDashboard);
document.querySelector("#current-date").textContent = new Intl.DateTimeFormat("en-NG", {
  weekday: "long", day: "numeric", month: "long", year: "numeric",
}).format(new Date());
loadDashboard();
