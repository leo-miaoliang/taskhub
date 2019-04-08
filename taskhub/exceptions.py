class TaskHubException(Exception):
    """
    Base class for all taskhub's errors.
    Each custom exception should be derived from this class
    """
    status_code = 500

class TaskHubNotFoundException(TaskHubException):
    """Raise when the requested object/resource is not available in the system"""
    status_code = 404

class TaskNotFound(TaskHubNotFoundException):
    """Raise when a task is not available in the system"""
    pass