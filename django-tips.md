---
layout: page
permalink: /django-tips
title: Django Tips
---

{% include tag-pages-loop.html tagName='Django' %}

## Debugging
```python
import pdb
pdb.set_trace()
```

## Testing
We used Pytest which is built-in.

Testing tools like mocks and factories are also built in.
To run tests: `poetry run pytest`.

Annotations to mark tests that access the DB

```python
@pytest.mark.django_db
@patch("psycopg2.connect")
```

## Celery
- Tasks. These use annotations like `@task`
- Signals. These are a triggering mechanisms.

## Inspecting objects in the console
Rails:
```rb
object.inspect
```

Django:
```python
Object.__dict__
```
